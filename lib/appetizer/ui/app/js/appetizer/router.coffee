# A superclass for Backbone.router. It adds the following features:
# * Register dynamic routes: the method @dynamicRoutes, if present,
#   is executed when initializing the router. Using the provided @register
#   method, it is then possible to register routes within the @dynamicRoutes
#   method.
#
# * Components facilities: the property @components should contain an
#   array of components used in the application, such as "page", "panel",
#   "sidebar", etc..
#   For each component, a method showFoo is created, which can then be used
#   to show a component. For instance, showPage App.View.Page, options. Upon
#   calling showFoo App.View.Bar the following is performed:
#     - Call @foo.hide true if @foo exists
#     - Instanciate a fresh @foo = new App.View.Bar options
#     - Save current route in @foo.currentRoute
#     - Emit "foo:showing", @foo
#     - Call @foo.show()
#     - Emit "foo:shown", @foo when @foo has been shown
#
#   Component facilites can be used to properly implement your application's
#   logic. For instance, you can do the following:
#     components: ["page", "sidebar"]
#
#     initialize: ->
#       # Show the sidebar corresponding to current shown page.
#       @bind "page:shown", (page) -> @showSidebar @findSidebarForPage(page)

class Appetizer.Router extends Backbone.Router
  initialize: ->
    @children = []
  
    @dynamicRoutes() if @dynamicRoutes?

    # Create showItem functions

    if @components?
      @addShowFunction item for item in @components

  register: (route, name) =>
    @route route, name, this[name]

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

  addShowFunction: (item) ->
    fn = "show#{item.charAt(0).toUpperCase()}#{item.slice 1}"

    this[fn] = (kind, options) ->
      if this[item]?
        this[item].hide true
        @removeChild this[item]

      this[item] = @createChild(kind, options)
      this[item].currentRoute = Backbone.history.getFragment()

      @trigger "#{item}:showing", this[item]
      this[item].bind "shown", => @trigger "#{item}:shown", this[item]
      this[item].show()
