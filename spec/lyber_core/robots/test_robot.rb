require 'lyber_core'

class TestRobot < LyberCore::Robots::Robot
  def process_item(work_item)
    LyberCore::Log.debug("TestRobot: Start time is : #{Time.new}")
  end
end