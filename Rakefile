require 'rubygems'
require 'rake'
require 'bundler'


begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end


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
    
    # These are a copy of the requirements in Gemfile
    # Gemfile should be the canonical version, and listing
    # requirements twice is a temporary measure that will be
    # fixed once jeweler 1.5 is out of beta. See note below. 
    
    gem.add_dependency "active-fedora", ">=1.1.13"
    gem.add_dependency "actionpack", "2.3.9"
    gem.add_dependency "activesupport", "2.3.9"
    gem.add_dependency "bagit", "0.1.0"
    gem.add_dependency "bundler", ">= 1.0.0"
    gem.add_dependency "columnize", "0.3.1"
    gem.add_dependency "facets", "2.8.4"
    gem.add_dependency "gemcutter", "0.6.1"
    gem.add_dependency "git", "1.2.5"
    gem.add_dependency "haml", "2.2.24"
    gem.add_dependency "hanna", "0.1.12"
    gem.add_dependency "jeweler", ">= 1.4"
    gem.add_dependency "json_pure", "1.4.6"
    gem.add_dependency "linecache", "0.43"
    gem.add_dependency "mime-types", "1.16"
    gem.add_dependency "multipart-post", "1.0.1"
    gem.add_dependency "nokogiri", "1.4.3.1"
    gem.add_dependency "om"
    gem.add_dependency "rake", "0.8.7"
    gem.add_dependency "rdoc", "2.3.0"
    gem.add_dependency "roxml", "3.1.5"
    gem.add_dependency "rspec", "1.3.0"
    gem.add_dependency "rubyforge", "2.0.4"
    gem.add_dependency "ruby-debug", "0.10.3"
    gem.add_dependency "semver", "0.1.0"
    gem.add_dependency "solr-ruby", "0.0.8"
    gem.add_dependency "systemu", ">= 1.2.0"
    gem.add_dependency "validatable", "1.6.7"
    gem.add_dependency "xml-simple", "1.0.12"
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    
    # ####################################################
    # NB: Once jeweler 1.5 is out of beta, we should stop maintaining requirements
    # in two places. Ideally, these are maintained only in the Gemfile. Once we're 
    # ready to upgrade to jeweler 1.5, remove the dependency requirements above and
    # replace them with just the line below, "gem.add_bundler_dependencies"
    # -- Bess
    # gem.add_bundler_dependencies # These are specified in Gemfile
    # ####################################################
    
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
  t.threshold = 54.7
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


