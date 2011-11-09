require "appetizer/setup"
require "appetizer/ui/page"
require "sass"
require "securerandom"
require "sinatra/base"
require "yajl"

module Appetizer
  module UI
    def self.registered app

      # Where does the one-page HTML template live?

      app.set :page, "views/app.html"

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

      # Set up cookie sessions and authenticity token checking. Add
      # some basic defaults, but allow them to be overridden.

      app.use Rack::Session::Cookie,
        key:    (ENV["APPETIZER_COOKIE_NAME"] || "app-session"),
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

        def page
          @page ||= Appetizer::UI::Page.new settings.page
        end
      end

      # Serve up a given SCSS file.

      app.get "/css/:name.css" do |name|
        scss :"css/#{name}"
      end

      # Serve up a combined JavaScript file.

      app.get "/js/all.js" do
        content_type :js, charset: "utf-8"

        File.open "public/js/all.js", "wb" do |f|
          f.write page.javascripts.map { |js| File.read "public/#{js}" }.
            join "\n" + ";" * 80 + "\n"
        end
      end
    end
  end
end

Sinatra.register Appetizer::UI
