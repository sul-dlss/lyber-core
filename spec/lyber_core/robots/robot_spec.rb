# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'robot "bases"' do
  let(:druid) { 'druid:test1234' }
  let(:wf_name) { 'testWF' }
  let(:step_name) { 'test-step' }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client, update_status: true, update_error_status: true)
  end

  shared_examples '#perform' do
    let(:test_class) { test_robot } # default
    let(:logged) { capture_stdout { test_class.perform druid } }
    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
      allow(workflow_client).to receive(:workflow_status).with('dor', druid, wf_name, step_name).and_return('queued')
    end

    it "updates workflow to 'completed' if work processes without error" do
      expect(logged).to match(/#{druid} processing/).and match(/work done\!/)

      expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'completed',
                                                                    elapsed: Float,
                                                                    note: Socket.gethostname)
    end

    context 'correct state returned' do
      let(:test_class) do
        Class.new(test_robot) do
          def perform(_druid)
            super && LyberCore::Robot::ReturnState.new(status: 'skipped')
          end
        end
      end

      it "updates workflow to 'skipped'" do
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)

        expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                      workflow: wf_name,
                                                                      process: step_name,
                                                                      status: 'skipped',
                                                                      elapsed: Float,
                                                                      note: Socket.gethostname)
      end
    end

    context 'when correct state and a note returned' do
      let(:test_class) do
        Class.new(test_robot) do
          def perform(_druid)
            super && LyberCore::Robot::ReturnState.new(note: 'some note to pass back to workflow')
          end
        end
      end

      it "updates workflow to 'completed' and sets a custom note" do
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)

        expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                      workflow: wf_name,
                                                                      process: step_name,
                                                                      status: 'completed',
                                                                      elapsed: Float,
                                                                      note: 'some note to pass back to workflow')
      end
    end

    context 'when skipped state and a note returned' do
      let(:test_class) do
        Class.new(test_robot) do
          def perform(_druid)
            super && LyberCore::Robot::ReturnState.new(status: 'skipped', note: 'some note to pass back to workflow')
          end
        end
      end

      it "updates workflow to 'skipped' and sets a custom note" do
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)

        expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                      workflow: wf_name,
                                                                      process: step_name,
                                                                      status: 'skipped',
                                                                      elapsed: Float,
                                                                      note: 'some note to pass back to workflow')
      end
    end

    context 'using a ReturnState constant' do
      let(:test_class) do
        Class.new(test_robot) do
          def perform(_druid)
            super && LyberCore::Robot::ReturnState.SKIPPED
          end
        end
      end

      it "updates workflow to 'skipped'" do
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)

        expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                      workflow: wf_name,
                                                                      process: step_name,
                                                                      status: 'skipped',
                                                                      elapsed: Float,
                                                                      note: Socket.gethostname)
      end
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      expect(workflow_client).to receive(:update_error_status).with(druid: druid, workflow: wf_name, process: step_name, error_msg: /work error/, error_text: Socket.gethostname)
      allow_any_instance_of(test_robot).to receive(:perform).and_raise('work error') # exception swallowed by Robot exception handler
      expect(logged).to match /work error/
    end

    it "processes jobs when workflow status is 'queued' for this object and step" do
      expect(logged).to match /work done\!/

      expect(workflow_client).to have_received(:update_status).with(druid: druid,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'completed',
                                                                    elapsed: Float,
                                                                    note: Socket.gethostname)
    end

    it "skips jobs when workflow status is not 'queued' for this object and step" do
      expect(workflow_client).to receive(:workflow_status).with('dor', druid, wf_name, step_name).and_return('completed')
      expect(logged).to match /Item druid\:.* is not queued.*completed/m
    end
  end

  describe LyberCore::Robot do
    let(:test_robot) do
      Class.new do
        include LyberCore::Robot
        def initialize
          super('dor', 'testWF', 'test-step')
        end

        def perform(_druid)
          LyberCore::Log.info 'work done!'
        end
      end
    end
    it_behaves_like '#perform'
  end
end
