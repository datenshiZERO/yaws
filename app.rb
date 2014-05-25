Bundler.require

require 'sinatra/asset_pipeline'

class App < Sinatra::Base
  set :assets_precompile, %w(app.js app.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_host, 'datenshizero.github.io'
  set :assets_css_compressor, :sass
  set :assets_js_compressor, :uglifier

  Sprockets::Helpers.prefix = "/yaws/assets"
  register Sinatra::AssetPipeline

  get '/' do
    haml :index
  end
  get '/about.?:html?' do
    haml :about
  end
end
