require 'lyber_core'

class TestRobotWithNote
  include LyberCore::Robot

  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(druid)
    LyberCore::Log.info 'work done!'
    return LyberCore::Robot::ReturnState.new(note: 'some note to pass back to workflow')
  end
end
