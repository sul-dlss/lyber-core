require 'lyber_core'

class TestRobotWithNoteAndSkip
  include LyberCore::Robot

  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(_druid)
    LyberCore::Log.info 'work done!'
    LyberCore::Robot::ReturnState.new(status: 'skipped', note: 'some note to pass back to workflow')
  end
end
