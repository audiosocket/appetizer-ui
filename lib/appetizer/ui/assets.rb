require "coffee-script"
require "eco"
require "fileutils"
require "sass"
require "sinatra/base"
require "sprockets"
require "uglifier"
require "yui/compressor"

module App
  def self.assets
    @sprockets ||= Sprockets::Environment.new.tap do |s|
      s.register_bundle_processor "application/javascript", :uglifier do |ctx, data|
        Uglifier.compile data
      end

      s.register_bundle_processor "text/css", :yui do |ctx, data|
        YUI::CssCompressor.new.compress data
      end

      # NOTE: Seems like Sprockets' built-in FileStore is kinda busted
      # in the way it creates directories or processes key names (or I
      # don't understand it yet), so we're manually creating the
      # over-nested directory for the moment.

      FileUtils.mkdir_p "tmp/sprockets/sprockets"
      s.cache = Sprockets::Cache::FileStore.new "tmp/sprockets"

      %w(css img js views).each do |d|
        s.append_path "./app/#{d}"
        s.append_path "./vendor/#{d}"
      end
    end
  end
end

module Appetizer
  module UI
    module Assets
      def self.manifest
        return @manifest if defined? @manifest

        @manifest = Hash.new { |h, k| k }

        if File.file? file = "public/assets/manifest.yml"
          require "yaml"
          @manifest.merge! YAML.load File.read file
        end

        @manifest
      end

      def self.registered app
        app.helpers do
          def asset name
            if App.production?
              return cdnify "/assets/#{Appetizer::UI::Assets.manifest[name]}"
            end

            cdnify "/assets/#{App.assets[name].logical_path}"
          end

          def assets name
            return [asset(name)] if App.production?

            asset = App.assets[name]

            [asset.dependencies, asset].flatten.map do |dep|
              cdnify "/assets/#{dep.logical_path}?body=true"
            end
          end

          def cdnify path
            [ENV["APPETIZER_CDN_URL"], path].compact.join "/"
          end
        end
      end
    end
  end
end

Sinatra.register Appetizer::UI::Assets