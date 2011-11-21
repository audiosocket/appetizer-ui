# Shockingly enough, a superclass for views. Provides hooks and
# abstractions for incoming and outgoing bindings, parent and child
# views, default template rendering, async actions before show, and
# show()/hide()/makeVisible() helpers on top of render() and remove().

window.Appetizer ||= {}

class Appetizer.View extends Backbone.View

  # Subclasses must always call `super` in their initializers:
  # Important binding, parent, and child relationships get created.

  initialize: (options) ->
    @bindings = []
    @children = []
    @parent   = options.parent if options?.parent?

  # Add a child `view`. Its `parent` will be set to `this`, and it
  # will be dismissed when this view is dismissed.

  addChild: (view) ->
    view.parent = this
    @children.push view
    this

  # Hook to allow async processes to occur before and after showing
  # the view. A bound callback `fn` is passed to this method by
  # `show`, and should be called when the view is ready to be shown.

  aroundShow: (fn) -> fn()

  # Bind `fn` to an `event` on `src`, remembering that we've bound it
  # for future unbinding. Use this instead of calling `bind` directly
  # on other sources. Returns `this`.

  bindTo: (src, event, fn) ->
    src.bind event, fn, this
    @bindings.push evt: event, fn: fn, src: src
    this

  # Create and return a new instance of `kind`, passing along
  # `options` to the constructor. Add it as a child view.

  createChild: (kind, options) ->
    child = new kind options
    @addChild child
    child

  # Indicate that this view is no longer necessary. Optionally takes a
  # DOM event `e` and calls `preventDefault` on it to make wiring
  # easier. Unbinds all incoming and outgoing events, calls `dismiss`
  # on all children, and removes this view from any parent it might
  # have. Returns `this`.

  hide: (e) ->
    e.preventDefault() if e?.preventDefault?

    @remove()

    @trigger "hidden"
    @unbind()

    _(@children).chain().clone().each (c) -> c.hide() if c.hide?
    @parent.removeChild this if @parent?.removeChild

    this

  # Hook to provide actual DOM insertion/manipulation for the
  # view. The default implementation logs an error message to the
  # console.

  makeVisible: ->
    console.log "Can't make #{this.constructor.name} visible."

  # Remove `view` from this view's list of children. Returns `this`.

  removeChild: (view) ->
    @children.splice @children.indexOf(view), 1
    this

  # Render the contents of the view. Updates the view element's
  # contents, but doesn't do any other manipulation. Uses a JST based
  # on either the view class' `template` default value or a `template`
  # key passed in to the constructor. Triggers a "rendered" event
  # after the element's contents are in place. Returns `this`.
  #
  # Assumes that views are under a "client/" prefix and that their
  # template functions are available on a "JST" global.

  render: =>
    template = @options.template || @template || "appetizer/missing"
    renderer = JST["client/#{template}"] or JST["client/appetizer/missing"]

    $(@el).html renderer this
    @trigger "rendered"

    this

  # Display this view. Possibly asynchronous: Passes a bound callback
  # to `beforeShow` that will call `makeVisible` when the view is
  # ready for display. The default implementation of `makeVisible`
  # calls the callback immediately. Returns `this`.

  show: ->
    @aroundShow =>
      @makeVisible()
      @trigger "shown"

    this

  # Unbind any listeners who have bound themselves to us, and unbind
  # any listeners we've bound to others. Returns `this`.

  unbind: ->
    super # from Backbone.Events
    b.src.unbind b.evt, b.fn for b in @bindings
    this

  # Unbind all events we may have bound on `src`. Returns `this`.

  unbindFrom: (src) ->
    b.src.unbind b.evt, b.fn for b in @bindings when b.src is src
    this
