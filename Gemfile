source 'https://rubygems.org'

# Specify your gem's dependencies in signed_form.gemspec
gemspec

rails_version = ENV['RAILS_VERSION'] || 'latest'

case rails_version
when 'latest'
  gem 'rails'
when 'main', 'master'
  git 'https://github.com/rails/rails.git', branch: 'main' do
    gem 'rails'
    gem 'actionpack'
    gem 'activemodel'
  end
when /-stable$/
  gem 'rails', github: 'rails/rails', branch: rails_version
else
  gem 'rails', rails_version
end
