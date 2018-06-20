describe 'robot "bases"' do
  let(:druid) { 'druid:test1234' }
  let(:wf_name) { 'testWF' }
  let(:step_name) { 'test-step' }

  shared_examples '#perform' do
    let(:test_class) { test_robot } # default
    let(:logged) { capture_stdout { test_class.perform druid } }
    before do
      allow(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('queued')
    end

    it "updates workflow to 'completed' if work processes without error" do
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed',
                                                                            elapsed: Float,
                                                                            note: Socket.gethostname)
      expect(logged).to match(/#{druid} processing/).and match(/work done\!/)
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
        expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'skipped',
                                                                              elapsed: Float,
                                                                              note: Socket.gethostname)
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)
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
        expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed',
                                                                              elapsed: Float,
                                                                              note: 'some note to pass back to workflow')
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)
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
        expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'skipped',
                                                                              elapsed: Float,
                                                                              note: 'some note to pass back to workflow')
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)
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
        expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'skipped',
                                                                              elapsed: Float,
                                                                              note: Socket.gethostname)
        expect(logged).to match(/#{druid} processing/).and match(/work done\!/)
      end
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      expect(Dor::WorkflowService).to receive(:update_workflow_error_status).with('dor', druid, wf_name, step_name, /work error/, error_text: Socket.gethostname)
      allow_any_instance_of(test_robot).to receive(:perform).and_raise('work error') # exception swallowed by Robot exception handler
      expect(logged).to match /work error/
    end

    it "processes jobs when workflow status is 'queued' for this object and step" do
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with('dor', druid, wf_name, step_name, 'completed',
                                                                            elapsed: Float,
                                                                            note: Socket.gethostname)
      expect(logged).to match /work done\!/
    end

    it "skips jobs when workflow status is not 'queued' for this object and step" do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', druid, wf_name, step_name).and_return('completed')
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

  describe LyberCore::Base do
    let(:test_robot) do
      Class.new(LyberCore::Base) do
        def self.worker
          new('dor', 'testWF', 'test-step')
        end

        def perform(_druid)
          logger.info 'work done!'
        end
      end
    end
    it_behaves_like '#perform'
  end
end
