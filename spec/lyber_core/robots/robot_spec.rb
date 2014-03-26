require 'spec_helper'
require_relative 'test_robot'

describe LyberCore::Robot do

  describe "#perform" do
    let(:druid) { 'druid:test1234' }
    let(:wf_name) { 'testWF' }
    let(:step_name) { 'test-step' }

    it "updates workflow to 'completed' if work processes without error" do
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed', :elapsed => anything)
      logged = capture_stdout do
        TestRobot.perform druid
      end
      expect(logged).to match /work done\!/
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      expect(Dor::WorkflowService).to receive(:update_workflow_error_status).with('dor', druid, wf_name, step_name, /work error/)
      allow_any_instance_of(TestRobot).to receive(:perform).and_raise('work error')
      logged = capture_stdout do
          begin
            TestRobot.perform druid
            raise 'TestRobot.perform should have raised error but did not'
          rescue
            # swallow the 'work error' so the test can proceed
          end
      end
      expect(logged).to match /work error/
    end
  end

end