[![CircleCI](https://circleci.com/gh/sul-dlss/lyber-core/tree/main.svg?style=svg)](https://circleci.com/gh/sul-dlss/lyber-core/tree/main)
[![Test Coverage](https://api.codeclimate.com/v1/badges/472f67659e513e3d8ffa/test_coverage)](https://codeclimate.com/github/sul-dlss/lyber-core/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/472f67659e513e3d8ffa/maintainability)](https://codeclimate.com/github/sul-dlss/lyber-core/maintainability)
[![Gem Version](https://badge.fury.io/rb/lyber-core.svg)](https://badge.fury.io/rb/lyber-core)

# lyber_core

## Robot Creation

Create a class that mixes in `LyberCore::Robot`

* In the initializer, call `super` with the repository, workflow name, step name
* Your class `#perform` method will perform the actual work, with `druid` passed in as the one and only argument

```ruby
module Robots
  module DorRepo
    module Accession

      class Shelve
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform druid
          obj = Dor::Item.find(druid)
          obj.shelve
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

      class Shelve
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform druid
          obj = Dor::Item.find(druid)
          if some_logic_here_to_determine_if_shelving_occurs
            obj.shelve
            return LyberCore::Robot::ReturnState.new(status: 'completed') # set the final state to completed
#           return LyberCore::Robot::ReturnState.new(status: 'completed', note: 'some custom note to pass back to workflow') # set the final state to completed with a custom note

          else
            # just return skipped if we did nothing
            return LyberCore::Robot::ReturnState.new(status: 'skipped') # set the final state to skipped
#           return LyberCore::Robot::ReturnState.new(status: 'skipped', note: 'some custom note to pass back to workflow') # set the final state to skipped with a custom note
          end
        end

      end

    end
  end
end
```

## Robot Environment Setup

* Create a `config/boot.rb` file to load the classpath, classes and configuration that your robot will need in order to run.
See the [boot.rb file from the Common-Accessioning robot suite](https://github.com/sul-dlss/common-accessioning/blob/main/config/boot.rb) as an example

* Add `require 'resque/tasks'` to your `Rakefile`

* Create an `environment` task within your `Rakefile` that requires your `config/boot.rb` file

#### Example Rakefile modifications
```ruby
require 'robot-controller/tasks'
...
task :environment do
  require_relative 'config/boot'
end
```

## Start the Robot

* Use rake to start your robot, specifying the Resque queue as the environment variable `QUEUE`

```
$ QUEUE=accessionWF_shelve rake environment workers
```

## Enqueing a Job

```ruby
require 'resque'
Resque.enqueue_to('accessionWF_shelve'.to_sym, Robot::DorRepo::Accession::Shelve, 'druid:aa123bb4567')
```


## Releases
* **4.0** Remove unused classes and dependencies
* **3.0** Robot overhaul.  Use `resque` for job management and `bluepill` for process management
* **2.1.1** Relax dor-services-gem version requirement
* **2.0** Moved what was left of DorService (namely get_objects_for_workstep()) to dor-services' Dor::WorkflowService. Removed IdentityMetadata and DublinCore XML models. Factored out all remaining global constants. Removed unnecessary dependencies.
* **1.3** Started to use Dor::Config for workspace configuration
* **1.0.0** Factored all Dor::* classes and object models out of lyber-core and into a separate dor-services gem. WARNING: MAY BREAK COMPATIBILITY WITH PREVIOUS DOR-ENABLED CODE.
* **0.9.8** Created branch for legacy work "0.9-legacy".  Robots can now be configured with fully qualified workflows for prerequisites
  eg <i>dor:googleScannedBookWF:register-object</i>
* **0.9.2** Workflow bug fixes.  Last version that supports active-fedora 1.0.7
* We recommend that you **DO NOT USE** any version older than these

## Copyright

Copyright (c) 2014-16 Stanford University Library. See LICENSE for details.
