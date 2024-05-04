# frozen_string_literal: true

require 'spec_helper'

class Tester # rubocop:disable Lint/EmptyClass
end

RSpec.describe LyberCore::Robot do
  let(:druid) { 'druid:test1234' }
  let(:test_robot) do
    Class.new(LyberCore::Robot) do
      def perform_work
        Tester.bare_druid(bare_druid)
        Tester.workflow_service(workflow_service)
        Tester.object_client(object_client)
        Tester.cocina_object(cocina_object)
        Tester.druid_object(druid_object)
        Tester.lane_id(lane_id)
        logger.info 'work done!'
      end
    end
  end
  let(:wf_name) { 'testWF' }
  let(:step_name) { 'test-step' }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client, update_status: true, update_error_status: true, process: workflow_process)
  end
  let(:workflow_process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'lane1') }

  let(:robot) { test_robot.new('testWF', 'test-step') }
  let(:logger) { instance_double(Logger, info: true, debug: true, warn: true, error: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:druid_object) { instance_double(DruidTools::Druid) }

  before do
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(workflow_client).to receive(:workflow_status).with(druid:, workflow: wf_name,
                                                             process: step_name).and_return('queued')
    allow(robot).to receive(:logger).and_return(logger)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(DruidTools::Druid).to receive(:new).and_return(druid_object)
    # There is actually no Settings.stacks locally, so allowing expectations on nil
    RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
    allow(Settings.stacks).to receive(:local_workspace_root).and_return('/tmp')
    allow(Tester).to receive(:bare_druid)
    allow(Tester).to receive(:workflow_service)
    allow(Tester).to receive(:object_client)
    allow(Tester).to receive(:cocina_object)
    allow(Tester).to receive(:druid_object)
    allow(Tester).to receive(:lane_id)
  end

  context 'when work processes without error and no ReturnState' do
    it "updates workflow to 'completed'" do # rubocop:disable RSpec/MultipleExpectations
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')
      expect(Tester).to have_received(:bare_druid).with('test1234')
      expect(Tester).to have_received(:workflow_service).with(workflow_client)
      expect(Tester).to have_received(:object_client).with(object_client)
      expect(Tester).to have_received(:cocina_object).with(cocina_object)
      expect(Tester).to have_received(:druid_object).with(druid_object)
      expect(Tester).to have_received(:lane_id).with('lane1')
      expect(Dor::Services::Client).to have_received(:object).with(druid)
      expect(DruidTools::Druid).to have_received(:new).with(druid, '/tmp')

      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'completed',
                                                                    elapsed: Float,
                                                                    note: Socket.gethostname)
      expect(workflow_client).to have_received(:process).with(pid: druid,
                                                              workflow_name: wf_name,
                                                              process: step_name)
    end
  end

  context 'when skipped ReturnState' do
    let(:test_robot) do
      Class.new(LyberCore::Robot) do
        def perform_work
          logger.info 'work done!'
          LyberCore::ReturnState.new(status: 'skipped')
        end
      end
    end

    it "updates workflow to 'skipped'" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'skipped',
                                                                    elapsed: Float,
                                                                    note: Socket.gethostname)
    end
  end

  context 'when completed ReturnState with a note' do
    let(:test_robot) do
      Class.new(LyberCore::Robot) do
        def perform_work
          logger.info 'work done!'
          LyberCore::ReturnState.new(note: 'some note to pass back to workflow')
        end
      end
    end

    it "updates workflow to 'completed' and sets a custom note" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'started',
                                                                    elapsed: 1.0,
                                                                    note: Socket.gethostname)
      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'completed',
                                                                    elapsed: Float,
                                                                    note: 'some note to pass back to workflow')
    end
  end

  context 'when skipped ReturnState with a note' do
    let(:test_robot) do
      Class.new(LyberCore::Robot) do
        def perform_work
          logger.info 'work done!'
          LyberCore::ReturnState.new(status: 'skipped', note: 'some note to pass back to workflow')
        end
      end
    end

    it "updates workflow to 'skipped' and sets a custom note" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'skipped',
                                                                    elapsed: Float,
                                                                    note: 'some note to pass back to workflow')
    end
  end

  context 'when there is a problem with the work' do
    let(:test_robot) do
      Class.new(LyberCore::Robot) do
        def perform_work
          raise 'work error'
        end
      end
    end

    it "updates workflow to 'error' if there was a problem with the work" do
      robot.perform(druid)
      expect(logger).to have_received(:error).with(/work error/)
      expect(workflow_client).to have_received(:update_error_status).with(druid:,
                                                                          workflow: wf_name,
                                                                          process: step_name,
                                                                          error_msg: /work error/,
                                                                          error_text: Socket.gethostname)
    end
  end

  context 'when workflow status is not queued' do
    before do
      allow(workflow_client).to receive(:workflow_status).with(druid:, workflow: wf_name,
                                                               process: step_name).and_return('completed')
    end

    it 'skips the job' do
      robot.perform(druid)
      expect(logger).to have_received(:warn).with(/Item druid:.* is not queued.*completed/m)
    end
  end

  context 'when workflow status is not queued but we skip the check' do
    before do
      robot.check_queued_status = false
    end

    it 'runs the job' do
      robot.perform(druid)
      expect(logger).not_to have_received(:warn).with(/Item druid:.* is not queued.*completed/m)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')
      expect(Dor::Services::Client).to have_received(:object).with(druid)

      expect(workflow_client).to have_received(:update_status).with(druid:,
                                                                    workflow: wf_name,
                                                                    process: step_name,
                                                                    status: 'completed',
                                                                    elapsed: Float,
                                                                    note: Socket.gethostname)
    end
  end

  context 'when ReturnState is noop' do
    let(:test_robot) do
      Class.new(LyberCore::Robot) do
        def perform_work
          logger.info 'work done!'
          LyberCore::ReturnState.new(status: 'noop')
        end
      end
    end

    it 'only updates workflow for start' do
      robot.perform(druid)
      expect(workflow_client).to have_received(:update_status).once
    end
  end
end
