require 'spec_helper'
require_relative 'test_robot'

describe LyberCore::Robots::Robot do

  describe "#perform" do
    let(:druid) { 'druid:test1234' }
    let(:wf_name) { 'testWF' }
    let(:step_name) { 'test-step' }
    let(:bot) { TestRobot.new }

    it "updates workflow to 'completed' if work processes without error" do
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed', :elapsed => anything)
      bot.druid = druid
      logged = capture_stdout do
        bot.perform
      end
      expect(logged).to match /work done\!/
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      expect(Dor::WorkflowService).to receive(:update_workflow_error_status).with('dor', druid, wf_name, step_name, /work error/)
      expect(bot).to receive(:process_item).and_raise('work error')
      bot.druid = druid
      logged = capture_stdout do
          begin; bot.perform; rescue; end;   # swallow the 'work error' so the test can proceed
      end
      expect(logged).to match /work error/
    end
  end

end