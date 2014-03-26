require 'lyber_core'

class TestRobot < LyberCore::Robots::Robot
  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(druid)
    LyberCore::Log.info 'work done!'
  end
end