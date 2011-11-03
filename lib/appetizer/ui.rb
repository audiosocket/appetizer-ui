require "appetizer/setup"
require "appetizer/ui/page"
require "sass"
require "sinatra/base"
require "yajl"

module Appetizer
  module UI
    def self.registered app
      app.configure :production do
        require "rack/ssl"
        app.use Rack::SSL
      end

      app.configure :development do
        app.use Rack::CommonLogger, App.log

        begin
          require "sinatra/reloader"
          app.register Sinatra::Reloader
          app.also_reload "lib/**/*.rb"
        rescue LoadError
          warn "Want reloads? Add sinatra-reloader to your Gemfile."
        end
      end

      app.set :scss, cache_location: "tmp/sass-cache", style: :compact

      app.helpers do
        def created thing
          halt 201, json(thing)
        end

        def json thing
          content_type :json, charset: "utf-8"
          Yajl::Encoder.encode thing
        end
      end

      app.get "/css/:name.css" do |name|
        scss :"css/#{name}"
      end
    end
  end
end

Sinatra.register Appetizer::UI
