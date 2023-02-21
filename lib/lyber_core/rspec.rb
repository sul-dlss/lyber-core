# frozen_string_literal: true

module LyberCore
  # Methods to support testing robots
  module Rspec
    def test_perform(robot, druid)
      allow(robot).to receive(:druid).and_return(druid)
      robot.perform_work
    end
  end
end
