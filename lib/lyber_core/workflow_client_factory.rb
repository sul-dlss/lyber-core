# frozen_string_literal: true

module LyberCore
  # Factory for creating a workflow client
  class WorkflowClientFactory
    def self.build(logger: Sidekiq.logger)
      Dor::Workflow::Client.new(url: Settings.workflow.url, logger:, timeout: Settings.workflow.timeout)
    end
  end
end
