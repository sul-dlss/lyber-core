# this object defines the allowed states robots can optionally return upon completion
# if the return value of the "perform" step is an object of this type and the status value set an allowed value, 
#  it will be used to set the final workflow state for that druid
module LyberCore
  module Robot
    class ReturnState
      
      attr_reader :status
      ALLOWED_RETURN_STATES = %w{completed skipped}
      DEFAULT_RETURN_STATE  = 'completed'
      
      def initialize(value = DEFAULT_RETURN_STATE)
        self.status=value.to_s.downcase
      end
      
      def status=(value)
        raise 'invalid return state' unless ALLOWED_RETURN_STATES.include? value.to_s.downcase
        @status=value
      end
            
    end
  end
end