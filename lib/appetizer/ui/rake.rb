require "appetizer/rake"

# For Heroku.

task "assets:precompile" => :compile

desc "Compile the app's CSS and JS files."
task :compile => :init do
  ENV["APPETIZER_MINIFY_ASSETS"] = "true"

  require "appetizer/ui/assets"
  require "fileutils"
  require "yaml"

  manifest = {}

  App.assets.each_file do |path|
    next if File.basename(path).start_with? "_"
    next if %r|app/views| =~ path.to_s and not %r|app/views/client| =~ path.to_s
    next if path.to_s.end_with? ".jst.jade" # HACK

    if asset = App.assets[path]
      manifest[path] = asset.digest_path
      file = "public/assets/#{asset.digest_path}"

      FileUtils.mkdir_p File.dirname file
      asset.write_to file
    end
  end

  File.open "public/assets/manifest.yml", "wb" do |f|
    YAML.dump manifest, f
  end
end
