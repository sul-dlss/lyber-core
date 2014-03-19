require 'lyber_core'

class TestRobot < LyberCore::Robots::Robot
  def initialize(druid)
    super('dor', 'testWF', 'test-step', druid)
  end

  def process_item
    LyberCore::Log.info 'work done!'
  end
end