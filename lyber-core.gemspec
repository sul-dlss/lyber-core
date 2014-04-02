# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "lyber-core"
  s.version     = "3.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alpana Pande","Bess Sadler","Chris Fitzpatrick","Douglas Kim","Richard Anderson","Willy Mene","Michael Klein"]
  s.email       = ["wmene@stanford.edu"]
  s.homepage    = "http://github.com/sul-dlss/lyber-core"
  s.summary     = "Core services used by the SULAIR Digital Library"
  s.description = "Contains classes to make http connections with a client-cert, use Jhove, and call Suri\n" +
                    "Also contains core classes to build robots"
  s.executables = ['lc-gen-robot-scripts']

  s.required_rubygems_version = ">= 1.3.6"

  # Runtime dependencies

  # Bundler will install these gems too if you've checked out lyber-core source from git and run 'bundle install'
  # It will not add these as dependencies if you require lyber-core for other projects
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "lyberteam-gems-devel"
  s.add_development_dependency "rake", ">=0.8.7"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rspec"
  s.add_development_dependency "stompserver"
  s.add_development_dependency "yard"

  s.files        = Dir.glob("lib/**/*") + %w(LICENSE README.md) + Dir.glob('bin/*')
  s.bindir       = 'bin'
  s.require_path = 'lib'
end
