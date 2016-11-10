require 'lyber_core'

class TestRobotWithSkip
  include LyberCore::Robot

  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(druid)
    LyberCore::Log.info 'work done!'
    return LyberCore::Robot::ReturnState.new(status: 'skipped')
  end
end
