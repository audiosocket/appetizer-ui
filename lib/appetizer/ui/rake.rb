require "appetizer/rake"
require "vendorer"

# For Heroku.

desc "Download vendored assets"
task :vendorer => :init do
  Vendorer.new(update: true).parse File.read('Vendorfile')
end

task "assets:precompile" => :compile

desc "Compile the app's CSS and JS files."
task :compile => :init do
  ENV["APPETIZER_MINIFY_ASSETS"] = "true"

  require "appetizer/ui/assets"
  require "fileutils"
  require "yaml"

  manifest = {}

  if ENV["APPETIZER_ASSETS_ENTRY_POINTS"]
    assets = ENV["APPETIZER_ASSETS_ENTRY_POINTS"].split(",").map(&:strip).map do |name|
      next unless asset = App.assets[name]

      [asset.dependencies, asset]
    end.flatten.compact.uniq.map(&:pathname).each
  else
    assets = App.assets.each_file
  end


  assets.each do |path|
    next if File.basename(path).start_with? "_"
    next if %r|app/views| =~ path.to_s and not %r|app/views/client| =~ path.to_s

    if asset = App.assets[path]
      manifest[asset.logical_path] = asset.digest_path
      file = "public/assets/#{asset.digest_path}"

      FileUtils.mkdir_p File.dirname file
      asset.write_to file
    end
  end

  File.open "public/assets/manifest.yml", "wb" do |f|
    YAML.dump manifest, f
  end
end

if App.development?
  require "jasmine-headless-webkit"

  Jasmine::Headless::Task.new("test") do |t|
    t.colors = true
    t.keep_on_error = true
    t.jasmine_config = ENV["JASMINE_HEADLESS_CONFIG"] || "config/jasmine.yml"
  end
end
