require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "lyber-core"
    gem.summary = "Core services used by the SULAIR Digital Library"
    gem.description = "Contains classes to make http connections with a client-cert, use Jhove, and call Suri\n" +
                      "Also contains core classes to build robots"
    gem.email = "wmene@stanford.edu"
    gem.homepage = "http://github.com/wmene/lyber-core"
    gem.authors = ["Willy Mene"]
    
    gem.add_dependency 'active-fedora', '>= 1.0.7'
    gem.add_dependency 'systemu', '>= 1.2.0'
    gem.add_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "hanna", ">= 0.1.12"
    gem.add_dependency "roxml"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

require 'spec/rake/verify_rcov'
RCov::VerifyTask.new(:verify_rcov => ['clean', 'rcov']) do |t|
  t.threshold = 48.3
  t.index_html = 'coverage/index.html'
end

task :spec => :check_dependencies

task :default => :verify_rcov

require 'hanna/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lyber-core #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


