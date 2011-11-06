require "appetizer/setup"
require "appetizer/ui/page"
require "barista"
require "sass"
require "securerandom"
require "sinatra/base"
require "yajl"

module Appetizer
  module UI
    def self.registered app

      # Make sure that exception handling works the same in
      # development and production.

      app.set :show_exceptions, false

      # All production apps better be using SSL.

      app.configure :production do
        require "rack/ssl"
        app.use Rack::SSL
      end

      # This stack in primarily intended for deployment on Heroku, so
      # only bother to log requests in development mode. Heroku's
      # logging is more than enough in production.

      app.configure :development do
        app.use Rack::CommonLogger, App.log
      end

      # Build CSS under tmp, not in the project root.

      app.set :scss, cache_location: "tmp/sass-cache", style: :compact

      # Build CoffeeScript from src, dump it in tmp/js.

      Barista.output_root = "tmp/js"
      Barista.root        = "src"
      Barista.env         = App.env

      # Compile everything on startup.

      Barista.compile_all!

      # Dynamically recompile .coffee files, but not in production.

      app.use Barista::Filter unless App.production?

      # Serve tmp/js until we decide on an asset pipeline we like.

      app.use Rack::Static, root: "tmp", urls: ["/js"]

      # Set up cookie sessions and authenticity token checking. Add
      # some basic defaults, but allow them to be overridden.

      app.use Rack::Session::Cookie, key: (ENV["APPETIZER_COOKIE_NAME"] || "app-session"),
        secret: (ENV["APPETIZER_SESSION_SECRET"] || "app-session-secret")

      app.use Rack::Protection::AuthenticityToken

      app.before do
        session[:csrf] ||= SecureRandom.hex 32
      end

      app.helpers do

        # JSONify `thing` and respond with a `201`.

        def created thing
          halt 201, json(thing)
        end

        # Set a `:json` content-type and run `thing` through the Yajl
        # JSON encoder.

        def json thing
          content_type :json, charset: "utf-8"
          Yajl::Encoder.encode thing
        end
      end

      # Serve up a given SCSS file.

      app.get "/css/:name.css" do |name|
        scss :"css/#{name}"
      end
    end
  end
end

Sinatra.register Appetizer::UI
