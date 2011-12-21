class Appetizer.Router extends Backbone.Router
  initialize: ->
    @children = []
  
    # Register dynamic routes
  
    if @dynamicRoutes?
      routes = if _.isFunction(@dynamicRoutes) then @dynamicRoutes() else @dynamicRoutes

      @route route, handler, this[handler] for route, handler of routes

    # Create showItem functions
    if @components?
      @addShowFunction item for item in @components

  # Create an instance of a view, set this as the view's parent, and
  # add the view to the router's list of children.

  createChild: (kind, options) ->
    child = new kind options
    child.parent = this
    @children.push child
    child

  # Required for Appetizer.View hierarchy management.

  removeChild: (view) ->
    @children.splice _.indexOf(@children, view), 1
    this

  # Given a `kind` of view, create a new instance, hide() the previous
  # view, and show the new one. Used for "page" views.

  addShowFunction: (item) ->
    fn = "show#{item.charAt(0).toUpperCase()}#{item.slice 1}"

    this[fn] = (kind, options) ->
      this[item]?.hide true

      this[item] = @createChild(kind, options)

      @trigger "#{item}:showing", this[item]
      this[item].bind "shown", => @trigger "#{item}:shown", this[item]
      this[item].show()
