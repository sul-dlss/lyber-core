require 'rubygems'
require 'rake'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb', 'test/**/*.rb']
end

Spec::Rake::SpecTask.new(:functional) do |spec|
  spec.libs << 'lib' << 'spec' << 'test'
  spec.pattern = 'spec/**/*_spec.rb', 'test/**/*.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

Spec::Rake::SpecTask.new(:unit) do |spec|
  spec.libs << 'lib' << 'spec'  
  spec.pattern = 'test/**/*.rb'
  spec.rcov = true
end


desc "Run all functional tests"
      task :rcov => ["functional"] do
end


task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

task :default => [:rcov, :doc]

# To release the gem to the DLSS gemserver, run 'rake dlss_release'
require 'dlss/rake/dlss_release'
Dlss::Release.new


