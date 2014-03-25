# lyber_core

## Robot Creation

Create a class that derives from `LyberCore::Robots::Robot`

* The initializer will receive `druid`.  Call `super` with the repository, workflow name, step name and `druid`
* Your class `process_item` method will perform the actual work.  The `@druid` instance variable will contain the druid for the job

```ruby
module Accession
  class Shelve < LyberCore::Robots::Robot

    def initialize(druid)
      super('dor', 'accessionWF', 'shelve', druid)
    end

    def process_item
      obj = Dor::Item.find(@druid)
      LyberCore::Log.info "#{obj.datastreams.keys}"
    end

  end
end
```

## Robot Environment Setup

* Create a `config/boot.rb` file to load the classpath, classes and configuration that your robot will need in order to run.
See the [boot.rb file from the Common-Accessioning robot suite](https://github.com/sul-dlss/common-accessioning/blob/master/config/boot.rb) as an example

* Add `require 'resque/tasks'` to your `Rakefile`

* Create an `environment` task within your `Rakefile` that requires your `config/boot.rb` file

#### Example Rakefile modifications
```ruby
require 'resque/tasks'
...
task :environment do
  require_relative 'config/boot'
end
```

## Start the Robot

* Use rake to start your robot, specifying the Resque queue as the environment variable `QUEUE`

```
$ QUEUE=accessionWF_shelve rake environment resque:work
```

## Enqueing a Job

```ruby
require 'resque'
Resque.enqueue_to('accessionWF_shelve'.to_sym, Accession::Shelve, 'druid:aa123bb4567')
```


## Releases
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

Copyright (c) 2014 Stanford University Library. See LICENSE for details.
