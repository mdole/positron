#
# Migrates old gravity posts into the new article format.
#

_ = require 'underscore'
env = require 'node-env-file'
{ resolve } = require 'path'
env resolve __dirname, '../../.env'
async = require 'async'
cheerio = require 'cheerio'
moment = require 'moment'
{ ObjectId } = mongojs = require 'mongojs'
{ GRAVITY_MONGO_URL, GRAVITY_CLOUDFRONT_URL } = process.env

# Load the Positron & Gravity databases
db = require './db'
gravity = mongojs GRAVITY_MONGO_URL, ['posts', 'post_artist_features',
  'post_artwork_features', 'artworks']

# Convenience for killing the script on error
kill = (err) ->
  console.warn err
  process.exit 1

# Time it
start = moment()

# Remove all of the existing migrated posts & fetch the latest from Gravity
db.articles.remove { gravity_id: $ne: null }, (err) ->
  return kill(err) if err
  gravity.posts.find(published: true).toArray (err, posts) ->
    return kill(err) if err
    console.log "Migrating #{posts.length} posts...."

    # Fetch any artist/artwork features and begin mapping posts -> articles
    async.map posts, ((post, callback) ->
      $ = cheerio.load post.body if post.body
      queries = [
        (cb) -> gravity.post_artist_features.find(post_id: post._id).toArray cb
        (cb) -> gravity.post_artwork_features.find(post_id: post._id).toArray cb
      ]
      if post.attachments?[0]?._type is 'PostArtwork'
        queries.push (cb) ->
          gravity.artworks.findOne { _id: post.attachments?[0].artwork_id }, cb
      async.parallel queries, (err, results) ->

        # Denormalize Gravity features into the Positron schema
        featuredArtistIds = (feature.artist_id for feature in results[0])
        featuredArtworkIds = (feature.artwork_id for feature in results[1])
        artwork = results[2]

        # Map Gravity attachments into Positron sections
        sections = _.compact (for attachment in (post.attachments or [])
          switch attachment?._type
            when 'PostArtwork'
              {
                type: 'artworks'
                ids: [attachment?.artwork_id]
                layout: 'column_width'
              }
            when 'PostImage'
              {
                type: 'image'
                url: "#{GRAVITY_CLOUDFRONT_URL}/post_images/" +
                  "#{attachment?._id}/larger.jpg"
              }
            when 'PostLink'
              if attachment?.url?.match /youtube|vimeo/
                {
                  type: 'video'
                  url: attachment?.url
                }
          )
        sections.push { type: 'text', body: post.body } if $?('*').text()

        # Map the rest of the Gravity data into a Positron schema
        data =
          slugs: post._slugs
          author_id: ObjectId(post.author_id)
          thumbnail_title: post.title
          thumbnail_teaser: $?('p')?.first()?.text()
          thumbnail_image: switch post.attachments?[0]?._type
            when 'PostArtwork'
              img = artwork?.additional_images?[0]
              if img
                "http://static.artsy.net/additional_images/#{img._id}/" +
                "#{if v = img.image_version then v + '/' else ''}large.jpg"
              else
                artwork?.image_urls?.large or artwork?.image_urls?[0]
            when 'PostImage'
              "#{GRAVITY_CLOUDFRONT_URL}/post_images/" +
              "#{post.attachments?[0]?._id}/large.jpg"
            when 'PostLink'
              (
                post.attachments?[0]?.oembed_json?.thumbnail_url or
                post.attachments?[0]?.oembed_json?.url
              )
          tags: [moment(post.published_at).format('YYYY')]
          title: post.title
          published: post.published
          published_at: moment(post.published_at).format()
          updated_at: moment(post.updated_at).format()
          sections: sections
          featured_artist_ids: featuredArtistIds
          featured_artwork_ids: featuredArtworkIds
          gravity_id: post._id
        console.log "Mapped #{_.last post._slugs}"
        callback null, data
    ), (err, posts) ->
      return kill(err) if err

      # Bulk update the mapped posts into Positron
      bulk = db.articles.initializeOrderedBulkOp()
      bulk.insert(post) for post in posts
      bulk.execute (err, res) ->
        return kill(err) if err
        console.log "All done! Started migration #{moment().from(start)}. " +
          "Took #{moment().diff(start)}ms"
        process.exit()
