require "bundler/gem_tasks"

desc 'Generate documentation.'
task :rdoc do
  system 'yardoc'
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec
