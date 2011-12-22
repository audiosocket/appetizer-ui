window.Appetizer ||= {}

# All Backbone's classes that inherit from Backbone.Event
# are also given a "one" method, which can be used to fire
# a callback only on the next occurence of a given event.

one =
  one: (ev, callback, context) ->
    fn = ->
      callback.apply this, arguments
      this.unbind.apply this, [ev, fn]

    this.bind.apply this, [ev, fn, context]

_.extend Backbone.Model.prototype, one
_.extend Backbone.Collection.prototype, one
_.extend Backbone.View.prototype, one
_.extend Backbone.Router.prototype, one
