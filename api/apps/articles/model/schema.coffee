Joi = require 'joi'
Joi.objectId = require('joi-objectid') Joi
{ API_MAX, API_PAGE_SIZE } = process.env

#
# Input Schema
#
imageSection = (->
  @object().keys
    type: @string().valid('image')
    url: @string().allow('', null)
    caption: @string().allow('', null)
).call Joi

videoSection = (->
  @object().keys
    type: @string().valid('video')
    url: @string().allow('', null)
    cover_image_url: @string().allow('', null)
    layout: @string().allow('',null)
    background_color: @string().allow('',null)
).call Joi

fullscreenSection = (->
  @object().keys
    type: @string().valid('fullscreen')
    title: @string().allow('',null)
    intro: @string().allow('',null)
    background_url: @string().allow('',null)
    background_image_url: @string().allow('',null)
).call Joi

denormalizedArtwork = (->
  @object().keys
    type: @string().valid('artwork').default('artwork')
    id: @string().allow('', null)
    slug: @string().allow('', null)
    date: @string().allow('', null)
    title: @string().allow('', null)
    image: @string().allow('', null)
    partner: @object().keys
      name: @string().allow('', null)
      slug: @string().allow('', null)
    artist: @object().keys
      name: @string().allow('', null)
      slug: @string().allow('', null)
).call Joi

@inputSchema = (->
  id: @objectId()
  author_id: @objectId().required()
  author: @object().keys
    name: @string().allow('').default('')
    id: @objectId()
  tier: @number().default(2)
  thumbnail_title: @string().allow('', null)
  thumbnail_teaser: @string().allow('', null)
  thumbnail_image: @string().allow('', null)
  tags: @array().items(@string()).default([])
  title: @string().allow('', null)
  layout: @string().allow('left', 'center', null).default('center')
  published: @boolean().default(false)
  published_at: @date()
  scheduled_publish_at: @date().allow(null)
  lead_paragraph: @string().allow('', null)
  gravity_id: @objectId().allow('', null)
  hero_section: @alternatives().try(videoSection, imageSection, fullscreenSection).allow(null)
  sections: @array().items([
    imageSection
    videoSection
    @object().keys
      type: @string().valid('callout')
      thumbnail_url: @string().allow('',null)
      text: @string().allow('',null)
      article: @string().allow('',null)
      hide_image: @boolean().default(false)
      top_stories: @boolean().default(false)
    @object().keys
      type: @string().valid('embed')
      url: @string().allow('',null)
      height: @string().allow('',null)
      mobile_height: @string().allow('',null)
      layout: @string().allow('',null)
    @object().keys
      type: @string().valid('text')
      body: @string().allow('', null)
    @object().keys
      type: @string().valid('toc')
      links: @array().items(
        @object().keys
          name: @string().allow('', null)
          value: @string().allow('', null)
      ).allow(null).default([])
    @object().keys
      type: @string().valid('artworks')
      ids: @array().items(@objectId())
      layout: @string().allow('overflow_fillwidth', 'column_width', null)
      artworks: @array().items(denormalizedArtwork).allow(null).default([])
    @object().keys
      type: @string().valid('slideshow')
      items: @array().items [
        imageSection
        videoSection
        @object().keys
          type: @string().valid('artwork')
          id: @string()
      ]
    @object().keys
      type: 'image_set'
      images: @array().items([denormalizedArtwork, imageSection])
  ]).allow(null)
  primary_featured_artist_ids: @array().items(@objectId()).allow(null)
  featured_artist_ids: @array().items(@objectId()).allow(null)
  featured_artwork_ids: @array().items(@objectId()).allow(null)
  partner_ids: @array().items(@objectId()).allow(null)
  show_ids: @array().items(@objectId()).allow(null)
  fair_ids: @array().items(@objectId()).default([])
  fair_programming_ids: @array().items(@objectId()).default([])
  fair_artsy_ids: @array().items(@objectId()).default([])
  fair_about_ids: @array().items(@objectId()).default([])
  auction_ids: @array().items(@objectId()).default([])
  section_ids: @array().items(@objectId()).default([])
  biography_for_artist_id: @objectId().allow(null)
  featured: @boolean().default(false)
  exclude_google_news: @boolean().default(false)
  contributing_authors: @array().items([
    @object().keys
      id: @objectId().allow(null)
      name: @string().allow('', null)
    ]).default([])
  email_metadata: @object().keys
    image_url: @string().allow('',null)
    headline: @string().allow('',null)
    author: @string().allow('',null)
    credit_line: @string().allow('',null)
    credit_url: @string().allow('',null)
    custom_text: @string().allow('',null)
  is_super_article: @boolean().default(false)
  super_article: @object().keys
    partner_link: @string().allow('',null)
    partner_link_title: @string().allow('',null)
    partner_logo: @string().allow('',null)
    partner_logo_link: @string().allow('',null)
    partner_fullscreen_header_logo: @string().allow('',null)
    secondary_partner_logo: @string().allow('',null)
    secondary_logo_text: @string().allow('',null)
    secondary_logo_link: @string().allow('',null)
    footer_blurb: @string().allow('',null)
    related_articles: @array().items(@objectId()).allow(null)
  send_body: @boolean().default(false)
  channel_id: @objectId().allow(null).default(null)
  partner_channel_id: @objectId().allow(null).default(null)
  description: @string().allow('',null)
).call Joi

#
# Query Schema
#
@querySchema = (->
  access_token: @string()
  author_id: @objectId()
  published: @boolean()
  limit: @number().max(Number API_MAX).default(Number API_PAGE_SIZE)
  offset: @number()
  section_id: @objectId()
  artist_id: @objectId()
  artwork_id: @objectId()
  fair_ids: @array()
  fair_id: @objectId()
  fair_programming_id: @objectId()
  fair_artsy_id: @objectId()
  fair_about_id: @objectId()
  show_id: @objectId()
  partner_id: @objectId()
  auction_id: @objectId()
  sort: @string()
  tier: @number()
  featured: @boolean()
  exclude_google_news: @boolean()
  super_article_for: @objectId()
  q: @string()
  all_by_author: @objectId()
  tags: @array()
  is_super_article: @boolean()
  biography_for_artist_id: @objectId()
  layout: @string()
  has_video: @boolean()
  channel_id: @objectId()
  ids: @array()
).call Joi
