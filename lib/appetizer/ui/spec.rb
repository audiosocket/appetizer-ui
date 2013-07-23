require "sinatra/base"
require "appetizer/ui/assets"

module Appetizer
  module UI
    module Spec
      def self.registered app
        return if App.production?

        %w(css img js views).each do |d|
          App.assets.append_path File.expand_path("../jasmine/#{d}", __FILE__)
        end

        app.get "/specs" do
          begin
            erb :specs, layout: false
          rescue
            template = File.expand_path "../jasmine/views/specs.erb", __FILE__
            erb File.read(template), layout: false
          end
        end
      end
    end
  end
end

Sinatra.register Appetizer::UI::Spec
