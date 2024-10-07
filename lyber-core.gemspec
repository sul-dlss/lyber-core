# frozen_string_literal: true

require_relative "lib/lyber_core/version"

Gem::Specification.new do |s|
  s.name        = 'lyber-core'
  s.version     = LyberCore::VERSION
  s.licenses    = ['Apache-2.0']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alpana Pande', 'Bess Sadler', 'Chris Fitzpatrick', 'Douglas Kim', 'Richard Anderson', 'Willy Mene', 'Michael Klein', 'Darren Weber', 'Peter Mangiafico']
  s.email       = ['sul-devops-team@lists.stanford.edu']
  s.homepage    = 'http://github.com/sul-dlss/lyber-core'
  s.summary     = 'Core services used by the SUL Digital Library'
  s.description = "Contains classes to make http connections with a client-cert, use Jhove, and call Suri\n" \
                    'Also contains core classes to build robots'

  s.required_ruby_version = '>=3.2'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activesupport'
  s.add_dependency 'config'
  s.add_dependency 'dor-services-client', '~> 15.0'
  s.add_dependency 'dor-workflow-client', '>= 7.4' # 7.4.0 has the ability to set and return workflow context
  s.add_dependency 'druid-tools'
  s.add_dependency 'honeybadger'
  s.add_dependency 'sidekiq', '~> 7.0'
  s.add_dependency 'zeitwerk'

  # Bundler will install these gems too if you've checked out lyber-core source from git and run 'bundle install'
  # It will not add these as dependencies if you require lyber-core for other projects
  s.add_development_dependency 'rake', '>=0.8.7'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 1.24'
  s.add_development_dependency 'rubocop-capybara'
  s.add_development_dependency 'rubocop-factory_bot'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rubocop-rspec_rails'
  s.add_development_dependency 'simplecov'

  s.files        = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  s.bindir       = 'bin'
  s.require_path = 'lib'
end
