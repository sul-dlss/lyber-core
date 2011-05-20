# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
  
Gem::Specification.new do |s|
  s.name        = "lyber-core"
  s.version     = "0.9.7.4"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alpana Pande","Bess Sadler","Chris Fitzpatrick","Douglas Kim","Richard Anderson","Willy Mene","Michael Klein"]
  s.email       = ["wmene@stanford.edu"]
  s.homepage    = "http://github.com/wmene/lyber-core"
  s.summary     = "Core services used by the SULAIR Digital Library"
  s.description = "Contains classes to make http connections with a client-cert, use Jhove, and call Suri\n" +
                    "Also contains core classes to build robots"
 
  s.required_rubygems_version = ">= 1.3.6"
  
  # Runtime dependencies
  s.add_dependency "actionpack"  # Debatable as to whether we need to declare this
  s.add_dependency "active-fedora", ">=1.2.6"
  s.add_dependency "bagit", ">=0.1.0"
  s.add_dependency "nokogiri", "=1.4.3.1"
  s.add_dependency "solr-ruby", ">=0.0.8"
  s.add_dependency "solrizer", ">= 0.3.1"   # There was a bug in 0.3.0, we need at least the version after
  s.add_dependency "stomp"
  s.add_dependency "systemu", ">= 1.2.0"
  s.add_dependency "validatable"
  
  # Bundler will install these gems too if you've checked out lyber-core source from git and run 'bundle install'
  # It will not add these as dependencies if you require lyber-core for other projects
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "haml"
  s.add_development_dependency "lyberteam-devel", ">=0.1.1"
  s.add_development_dependency "rake", ">=0.8.7"
  s.add_development_dependency "rcov"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rspec", "< 2.0" # We're not ready to upgrade to rspec 2
  s.add_development_dependency "ruby-debug"
  s.add_development_dependency "stompserver"
  s.add_development_dependency "yard"
 
  s.files        = Dir.glob("lib/**/*") + %w(LICENSE README.rdoc)
  s.require_path = 'lib'
end