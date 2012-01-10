module Appetizer
  module UI
    module Assets
      class Delivery < Struct.new(:app)
        require "rack/contrib/static_cache" if Assets.compiled?

        STATIC = {
          root: "public",
          urls: Dir["public/*"].map { |s| s[6..-1] }
        }

        def call env
          cached(env) || asset(env) || app.call(env)
        end

        def asset env
          if !Assets.compiled? and env["PATH_INFO"].start_with? "/assets"
            env["PATH_INFO"] = env["PATH_INFO"][7..-1]
            App.assets.call env
          end
        end

        def cached env
          Rack::StaticCache.new(app, STATIC).call env if Assets.compiled?
        end
      end
    end
  end
end
