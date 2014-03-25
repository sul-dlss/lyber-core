require 'lyber_core'

class TestRobot < LyberCore::Robots::Robot
  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def process_item
    LyberCore::Log.info 'work done!'
  end
end