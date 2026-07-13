# frozen_string_literal: true

module LyberCore
  # Methods to support testing robots
  module Rspec
    def test_perform(robot, druid, version: nil)
      allow(robot).to receive(:druid).and_return(druid)
      allow(robot).to receive(:version).and_return(version) if version
      robot.perform_work
    end
  end
end
