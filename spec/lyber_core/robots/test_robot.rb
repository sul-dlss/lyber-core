class TestRobot
  include LyberCore::Robot

  def initialize
    super('dor', 'testWF', 'test-step')
  end

  def perform(_druid)
    LyberCore::Log.info 'work done!'
  end
end
