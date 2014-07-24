require 'spec_helper'
require_relative 'test_robot'

describe LyberCore::Robot do

  describe "#perform" do
    let(:druid) { 'druid:test1234' }
    let(:wf_name) { 'testWF' }
    let(:step_name) { 'test-step' }

    it "updates workflow to 'completed' if work processes without error" do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('queued')
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed',
                                                                              :elapsed => an_instance_of(Float),
                                                                              :note => Socket.gethostname)
      logged = capture_stdout do
        TestRobot.perform druid
      end
      expect(logged).to match /Processing #{druid}/
      expect(logged).to match /work done\!/
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('queued')
      expect(Dor::WorkflowService).to receive(:update_workflow_error_status).with('dor', druid, wf_name, step_name, /work error/, :error_text => Socket.gethostname)
      allow_any_instance_of(TestRobot).to receive(:perform).and_raise('work error')
      logged = capture_stdout do
        TestRobot.perform druid
      end
      # exception swallowed by Robot exception handler
      expect(logged).to match /work error/
    end

    it "processes jobs when workflow status is 'queued' for this object and step" do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('queued')
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed',
                                                                              :elapsed => an_instance_of(Float),
                                                                              :note => Socket.gethostname)
      logged = capture_stdout do
        TestRobot.perform druid
      end
      expect(logged).to match /work done\!/
    end

    it "skips jobs when workflow status is not 'queued' for this object and step" do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('completed')
      logged = capture_stdout do
        TestRobot.perform druid
      end
      expect(logged).to match /Item is not queued.*completed/
    end
  end

end
