require "coffee-script"
require "eco"
require "fileutils"
require "sinatra/base"
require "sprockets"
require "appetizer/ui/globber"
require "uglifier"
require "yui/compressor"

module App
  def self.assets
    @sprockets ||= Sprockets::Environment.new.tap do |s|
      if Appetizer::UI::Assets.compiled?
        if Appetizer::UI::Assets.uglify?
          s.register_bundle_processor "application/javascript", :uglifier do |ctx, data|
            Uglifier.compile data, mangle: false, squeeze: false, seqs: false
          end
        end

        s.register_bundle_processor "text/css", :yui do |ctx, data|
          YUI::CssCompressor.new.compress data
        end
      end

      # NOTE: Seems like Sprockets' built-in FileStore is kinda busted
      # in the way it creates directories or processes key names (or I
      # don't understand it yet), so we're manually creating the
      # over-nested directory for the moment.

      unless Appetizer::UI::Assets.compiled?
        FileUtils.mkdir_p "tmp/sprockets/sprockets"
        s.cache = Sprockets::Cache::FileStore.new "tmp/sprockets"
      end

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
      def self.compiled?
        App.production? or ENV["APPETIZER_USE_COMPILED_ASSETS"]
      end

      def self.uglify?
        compiled? and not ENV["APPETIZER_NO_UGLIFY"]
      end

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
          def asset_apps
            apps = Dir.glob(Dir.pwd + "/app/js/*")
            apps.collect { |path| File.basename(path) if File.directory?(path) }.compact
          end

          def asset name
            if Appetizer::UI::Assets.compiled?
              return cdnify "/assets/#{Appetizer::UI::Assets.manifest[name]}"
            end

            cdnify "/assets/#{App.assets[name].logical_path}"
          end

          def assets *names
            names.flat_map do |name|
              next unless asset = App.assets[name]
              next asset name if Appetizer::UI::Assets.compiled?

              [asset.dependencies, asset].flatten.map do |dep|
                "/assets/#{dep.logical_path}?body=true"
              end
            end.compact
          end

          def cdnify path
            File.join [ENV["APPETIZER_CDN_URL"], path].compact
          end
        end
      end
    end
  end
end

Sinatra.register Appetizer::UI::Assets

# Required at the bottom so it can conditionally require a few things
# based on Appetizer::UI::Assets.compiled?.

require "appetizer/ui/assets/delivery"
