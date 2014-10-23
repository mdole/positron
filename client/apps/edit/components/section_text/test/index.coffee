benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ resolve } = require 'path'
React = require 'react'
require 'react/addons'
r =
  find: React.addons.TestUtils.findRenderedDOMComponentWithClass
  simulate: React.addons.TestUtils.Simulate

describe 'SectionText', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose $: require 'jquery'
      SectionText = benv.require resolve(__dirname, '../index')
      SectionText.__set__ 'Scribe', @Scribe = sinon.stub()
      SectionText.__set__ 'scribePluginToolbar', @scribePluginToolbar = sinon.stub()
      @component = React.renderComponent SectionText(
        section: new Backbone.Model { body: 'Foo to the bar' }
        onSetEditing: @onSetEditing = sinon.stub()
        editing: false
        key: 4
      ), $("<div></div>")[0], -> setTimeout -> done()

  afterEach ->
    benv.teardown()

  it "updates the section's body on click off", ->
    $(@component.refs.editable.getDOMNode()).html 'Hello'
    @component.onClickOff()
    @component.props.section.get('body').should.equal 'Hello'

  it 'removes the section if they click off and its empty', ->
    @component.props.section.destroy = sinon.stub()
    @component.props.section.set body: ''
    @component.onClickOff()
    @component.props.section.destroy.called.should.be.ok