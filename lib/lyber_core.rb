require 'dor-workflow-service'

require 'lyber_core/base'
require 'lyber_core/log'
require 'lyber_core/robot'
require 'lyber_core/return_state'

Dor::WorkflowService.configure(Dor::Config.workflow.url)
