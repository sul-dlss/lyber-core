# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'lyber-core'
  s.version     = '6.0.0'
  s.licenses    = ['Apache-2.0']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alpana Pande', 'Bess Sadler', 'Chris Fitzpatrick', 'Douglas Kim', 'Richard Anderson', 'Willy Mene', 'Michael Klein', 'Darren Weber', 'Peter Mangiafico']
  s.email       = ['sul-devops-team@lists.stanford.edu']
  s.homepage    = 'http://github.com/sul-dlss/lyber-core'
  s.summary     = 'Core services used by the SUL Digital Library'
  s.description = "Contains classes to make http connections with a client-cert, use Jhove, and call Suri\n" \
                    'Also contains core classes to build robots'

  s.required_rubygems_version = '>= 1.3.6'

  # Bundler will install these gems too if you've checked out lyber-core source from git and run 'bundle install'
  # It will not add these as dependencies if you require lyber-core for other projects
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rake', '>=0.8.7'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec', '~> 1.24'
  s.add_development_dependency 'yard'

  s.files        = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  s.bindir       = 'bin'
  s.require_path = 'lib'
end
