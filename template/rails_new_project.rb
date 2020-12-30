run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '2.7.2'
gem 'rails', '~> 6.1.0'
# Core
gem 'bootsnap', '>= 1.4.4', require: false
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 5.0'
gem 'redis', '~> 4.0'
# Security
gem 'devise'
# gem 'omniauth'
# gem 'recaptcha'
# Jobs
gem 'sidekiq'
gem 'sidekiq-status', "~> 1.1"
# JavaScript and assets
gem 'aws-sdk-s3', require: false
gem 'hotwire-rails', '~> 0.1.0'
gem 'image_processing', '~> 1.2'
gem 'jbuilder', '~> 2.7'
gem 'webpacker', '~> 5.x'
gem 'sass-rails', '>= 6'
# Ruby library
gem 'rexml'
# Mailing
gem 'mailgun_rails'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'annotate'
end

group :development do
  gem 'bullet'
  gem 'letter_opener'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'capybara'
  gem 'rspec-rails'
  gem 'webdrivers', '~> 4.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
RUBY

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.action_mailer\.delivery_method.*/, 'config.action_mailer.delivery_method = :letter_opener')

# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html class="text-gray-500 antialiased">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <%= favicon_link_tag asset_pack_path('media/images/bolt.png'), :rel => 'icon', :type =>  'image/png' %>
    <title><%= content_for?(:html_title) ? yield(:html_title) : "88pixels to-go starter template v2" %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
    <%= action_cable_meta_tag %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
HTML

file 'app/views/layouts/_flashes_notice.html.erb', <<-HTML
<div id="flash" class="w-full bg-black text-white py-2">
  <div class="text-xs text-center">
    <%= message %>
  </div>
</div>
<script>
  var flash = document.getElementById('flash')
  setTimeout(function(){
    flash.style.display = 'block' ? 'none' : 'block'
  }, 3500)
</script>
HTML

# Setting up routes
########################################
run 'rm config/routes.rb'
file 'config/routes.rb', <<-RUBY
Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'pages#home'
end
RUBY

# Setting up controller
########################################
file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  def home
  end
end
RUBY

# Setting up single view
########################################
file 'app/views/pages/home.html.erb', <<-HTML
<div class="text-center justify-center flex flex-col h-screen">
  <div class="flex justify-center mb-4">
    <%= image_tag asset_pack_path('media/images/bolt.png'), width: 200, height: 200, class: "shadow" %>
  </div>
  <p class="text-3xl font-extrabold text-gray-900 tracking-tight text-green-400">rails_new_project template v1 up and running</p>
  <p class="mt-1">Rails <%= Rails.version %>, Ruby 3.0.0, postgresql<br>tailwind v2, devise, redis, hotwire</p>
</div>
HTML

run 'bundle install'

# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db +  + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('devise:install')
  generate('devise:views')
  rails_command 'hotwire:install'

  # Git ignore
  ########################################
  append_file '.gitignore', <<-TXT
# Ignore .env file containing credentials.
.env*
# Ignore Mac and Linux file system files
*.swp
.DS_Store
  TXT


  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn / Tailwindcss / PostCSS / purgeCSS
  ########################################
  run 'yarn add tailwindcss@npm:@tailwindcss/postcss7-compat'
  run 'yarn add postcss@^7'
  run 'yarn add autoprefixer@^9'
  run 'yarn add typeface-inter'
  run 'rm app/javascript/packs/application.js'
  file 'app/javascript/packs/application.js', <<-JS
require("@rails/ujs").start();
require("@rails/activestorage").start();
require("channels")
require('css/application.scss');
require('typeface-inter');
require.context('../images', true);
  JS


  run 'npx tailwindcss init'
  run 'rm tailwind.config.js'
  file 'tailwind.config.js', <<-JS
module.exports = {
  purge: {
     content: [
        './app/**/*.html.erb',
        './app/helpers/**/*.rb'
  ]},
  theme: {
    fontFamily: {
      inter: ['Inter', 'sans-serif']
    },
    extend: {},
  },
  variants: {},
  plugins: [],
};
  JS

  run 'rm postcss.config.js'
  file 'postcss.config.js', <<-JS
module.exports = {
  plugins: [
    require('tailwindcss')('./tailwind.config.js'),
    require('autoprefixer'),
    require('postcss-import'),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009'
      },
      stage: 3
    })
  ]
};
  JS

  # Creating stylesheets + Adding favicon
  ########################################
  run 'mkdir app/javascript/css'
  file 'app/javascript/css/application.scss'
  file 'app/javascript/css/custom.scss'
  run 'curl -L https://raw.githubusercontent.com/jschee/rails_new_project/main/template/application.scss > app/javascript/css/application.scss'

  run 'mkdir app/javascript/images'
  run 'curl -L https://raw.githubusercontent.com/jschee/rails_new_project/main/template/bolt.png > app/javascript/images/bolt.png'

  # Git
  ########################################
  git :init
end
