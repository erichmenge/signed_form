source 'https://rubygems.org'

# Specify your gem's dependencies in signed_form.gemspec
gemspec

rails_version = ENV['RAILS_VERSION'] || 'master'

case rails_version
when /master/
  gem "rails", github: "rails/rails"
when /3-2-stable/
  gem "rails", github: "rails/rails", branch: "3-2-stable"
  gem "strong_parameters"
when /3-1-stable/
  gem "rails", github: "rails/rails", branch: "3-1-stable"
  gem "strong_parameters"
when /3-0-stable/
  gem "rails", github: "rails/rails", branch: "3-0-stable"
  gem "strong_parameters"
else
  gem "rails", ENV['RAILS_VERSION']
end
