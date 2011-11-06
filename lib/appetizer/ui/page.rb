require "nokogiri"

module Appetizer
  module UI

    # Represents the "static" HTML foundation page. Source HTML file
    # must have a <head> tag, a container with the "scripts" ID, and a
    # container with the "templates" ID.

    class Page
      attr_reader :source

      def initialize source, options = {}
        @config = {}
        @source = source
        @views  = options[:views] || "views/**/*.eco"
      end

      def []= k, v
        @config[k] = v
      end

      def render
        html = Nokogiri::HTML File.read @source
        head = html.css("head").first

        # Add all config values as meta tags.

        Nokogiri::HTML::Builder.with head do |h|
          @config.each { |k, v| h.meta name: k, value: v }
        end

        # Add all template files as script tags.

        templates = html.css("#templates").first

        Nokogiri::HTML::Builder.with templates do |t|
          Dir[@views].sort.each do |f|
            t.script "data-path" => f[6..-5], "type" => "text/x-template" do
              t.text File.read f
            end
          end
        end

        # Munge script tags.

        scripts = html.css("#scripts").first

        expanded = scripts.css("script[src]").map do |tag|
          Dir[File.join "{.,public}", tag[:src]].sort.map do |f|
            f.sub(/^public/, "").sub(/^\./, "/js").sub(/\.coffee$/, ".js")
          end
        end

        # Remove the original script tags.

        scripts.children.remove

        # Write some new ones.

        Nokogiri::HTML::Builder.with scripts do |s|
          expanded.flatten.each { |src| s.script src: src }
        end

        html.to_s
      end
    end
  end
end
