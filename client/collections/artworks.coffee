_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
{ ApiCollection } = require './mixins.coffee'

module.exports = class Artworks extends Backbone.Collection

  _.extend @prototype, ApiCollection

  url: "#{sd.API_URL}/artworks"