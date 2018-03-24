class TestRobotWithConstantState
  include LyberCore::Robot

  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(_druid)
    LyberCore::Log.info 'work done!'
    LyberCore::Robot::ReturnState.SKIPPED
  end
end
