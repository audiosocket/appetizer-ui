require "appetizer/rake"

desc "Precompile the app's CSS and JS files."
task "assets:precompile" => :init do
  require "appetizer/ui/assets"
  require "fileutils"
  require "yaml"

  manifest = {}

  App.assets.each_logical_path do |path|
    asset = App.assets[path]
    file  = "public/assets/#{asset.digest_path}"

    manifest[path] = asset.digest_path

    FileUtils.mkdir_p File.dirname file
    asset.write_to file
  end

  File.open "public/assets/manifest.yml", "wb" do |f|
    YAML.dump manifest, f
  end
end
