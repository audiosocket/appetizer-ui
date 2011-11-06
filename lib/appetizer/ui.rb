require "appetizer/setup"
require "appetizer/ui/page"
require "barista"
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
      end

      app.set :scss, cache_location: "tmp/sass-cache", style: :compact

      Barista.output_root = "tmp/js"
      Barista.root        = "src"
      Barista.env         = App.env

      Barista.compile_all!

      app.use Barista::Filter unless App.production?
      app.use Rack::Static, root: "tmp", urls: ["/js"]

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
