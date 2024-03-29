# frozen_string_literal: true

module LyberCore
  # this object defines the allowed states robots can optionally return upon completion
  # if the return value of the "perform" step is an object of this type and the status value is set an allowed value,
  #  it will be used to set the final workflow state for that druid
  class ReturnState
    attr_reader :status
    attr_accessor :note

    ALLOWED_RETURN_STATES = %w[completed skipped waiting noop].freeze
    DEFAULT_RETURN_STATE  = 'completed'

    def initialize(params = {})
      self.status = params[:status] || DEFAULT_RETURN_STATE
      self.note = params[:note] || ''
    end

    def status=(value)
      state = value.to_s.downcase
      raise 'invalid return state' unless ALLOWED_RETURN_STATES.include? state

      @status = state
    end
  end
end
