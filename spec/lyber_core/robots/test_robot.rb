require 'lyber_core'

class TestRobot < LyberCore::Robots::Robot
  def process_item(work_item)
    LyberCore::Log.info("TestRobot: Processing #{work_item.druid}")
  end
end