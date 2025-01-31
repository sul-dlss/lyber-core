[![CircleCI](https://circleci.com/gh/sul-dlss/lyber-core/tree/main.svg?style=svg)](https://circleci.com/gh/sul-dlss/lyber-core/tree/main)
[![codecov](https://codecov.io/github/sul-dlss/lyber-core/graph/badge.svg?token=FxCjczsxpG)](https://codecov.io/github/sul-dlss/lyber-core)
[![Gem Version](https://badge.fury.io/rb/lyber-core.svg)](https://badge.fury.io/rb/lyber-core)

# lyber_core

## Robot Creation

Create a class that subclasses `LyberCore::Robot`

* In the initializer, call `super` with the workflow name, step name
* Your class `#perform_work` method will perform the actual work; `druid` is available as an instance variable.

```ruby
module Robots
  module DorRepo
    module Accession

      class Shelve < LyberCore::Robot

        def initialize
          super('accessionWF', 'shelve')
        end

        def perform_work
          cocina_object.shelve
        end
      end
    end
  end
end
```

By default, the druid will be set to the completed state, but you can optionally have it set to skipped by creating a ReturnState object as shown below.
You can also return custom notes in this way
```ruby
module Robots
  module DorRepo
    module Accession

      class Shelve < LyberCore::Robot

        def initialize
          super('accessionWF', 'shelve')
        end

        def perform
          if some_logic_here_to_determine_if_shelving_occurs
            cocina_object.shelve
            return LyberCore::ReturnState.new(status: 'completed') # set the final state to completed
#           return LyberCore::ReturnState.new(status: 'completed', note: 'some custom note to pass back to workflow') # set the final state to completed with a custom note

          else
            # just return skipped if we did nothing
            return LyberCore::ReturnState.new(status: 'skipped') # set the final state to skipped
#           return LyberCore::ReturnState.new(status: 'skipped', note: 'some custom note to pass back to workflow') # set the final state to skipped with a custom note
          end
        end
      end
    end
  end
end
```

By default, a robot will not retry. To enable retries for specific errors:
```ruby
module Robots
  module DorRepo
    module Accession

      class Shelve < LyberCore::Robot
        def initialize
          super('accessionWF', 'shelve', retriable_exceptions: [Dor::Services::Client::Error])
        end

        def perform_work
          cocina_object.shelve
        end
      end
    end
  end
end
```

## Robot Environment Setup

Create a `config/boot.rb` containing:
```
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

LyberCore::Boot.up(__dir__)

# Any additional robot-specific configuratio.
```

The configuration must include:
```
redis_url: ~

workflow:
  url: http://workflow.example.com/workflow
  logfile: 'log/workflow_service.log'
  shift_age: 'weekly'
  timeout: 60
```

And optionally:
```
# For Dor Services Client
dor_services:
  url:  'https://dor-services-test.stanford.test'
  token: secret-token

# For Cocina::Models::Mapping::Purl
purl_url: 'https://purl-example.stanford.edu'

# For DruidTools::Druid
stacks:
  local_workspace_root: ~
```

The following environment variables can optionally be set:
* ROBOT_ENVIRONMENT
* ROBOT_LOG_LEVEL

## Robot Testing
Include the following in `rspec/spec_helper.rb`:
```
ENV['ROBOT_ENVIRONMENT'] = 'test'
require File.expand_path("#{__dir__}/../config/boot")

include LyberCore::Rspec
```

Robots can be invoked with:
```
test_perform(robot, druid)
```
to avoid the workflow updates in `perform()`.
