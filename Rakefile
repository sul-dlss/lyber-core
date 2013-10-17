require 'rubygems'
require 'rake'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

require 'rspec/core/rake_task'


desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

task :default => [:spec]

# To release the gem to the DLSS gemserver, run 'rake dlss_release'
require 'dlss/rake/dlss_release'
Dlss::Release.new


