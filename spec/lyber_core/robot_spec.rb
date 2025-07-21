# frozen_string_literal: true

require 'spec_helper'

class Tester # rubocop:disable Lint/EmptyClass
end

class TestRobot < LyberCore::Robot
  def initialize(return_state: nil, exception: nil)
    super('testWF', 'test-step', retriable_exceptions: [NotImplementedError])
    @return_state = return_state
    @exception = exception
  end

  def perform_work
    raise @exception if @exception

    Tester.bare_druid(bare_druid)
    Tester.object_client(object_client)
    Tester.cocina_object(cocina_object)
    Tester.druid_object(druid_object)
    Tester.lane_id(lane_id)
    logger.info 'work done!'
    @return_state
  end
end

RSpec.describe LyberCore::Robot do
  let(:druid) { 'druid:test1234' }

  let(:wf_name) { 'testWF' }
  let(:step_name) { 'test-step' }
  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'lane1', context: {}, status: 'queued') }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response, xml: '') }
  let(:object_workflow) do
    instance_double(Dor::Services::Client::ObjectWorkflow, process: workflow_process, find: workflow_response)
  end
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true) }

  let(:robot) { TestRobot.new(return_state:, exception:) }
  let(:return_state) { nil }
  let(:exception) { nil }
  let(:logger) { instance_double(Logger, info: true, debug: true, warn: true, error: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:druid_object) { instance_double(DruidTools::Druid) }

  before do
    allow(object_workflow).to receive(:process).with(step_name).and_return(workflow_process)
    allow(robot).to receive(:logger).and_return(logger)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(object_client).to receive(:workflow).with(wf_name).and_return(object_workflow)
    allow(DruidTools::Druid).to receive(:new).and_return(druid_object)
    # There is actually no Settings.stacks locally, so allowing expectations on nil
    RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
    allow(Settings.stacks).to receive(:local_workspace_root).and_return('/tmp')
    allow(Tester).to receive(:bare_druid)
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
      expect(Tester).to have_received(:object_client).with(object_client)
      expect(Tester).to have_received(:cocina_object).with(cocina_object)
      expect(Tester).to have_received(:druid_object).with(druid_object)
      expect(Tester).to have_received(:lane_id).with('lane1')
      expect(Dor::Services::Client).to have_received(:object).with(druid)
      expect(DruidTools::Druid).to have_received(:new).with(druid, '/tmp')

      expect(workflow_process).to have_received(:update).with(status: 'completed',
                                                              elapsed: Float,
                                                              note: Socket.gethostname)
      expect(object_workflow).to have_received(:process).with(step_name).once
    end
  end

  context 'when skipped ReturnState' do
    let(:return_state) { LyberCore::ReturnState.new(status: 'skipped') }

    it "updates workflow to 'skipped'" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_process).to have_received(:update).with(status: 'skipped',
                                                              elapsed: Float,
                                                              note: Socket.gethostname)
    end
  end

  context 'when completed ReturnState with a note' do
    let(:return_state) { LyberCore::ReturnState.new(note: 'some note to pass back to workflow') }

    it "updates workflow to 'completed' and sets a custom note" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_process).to have_received(:update).with(status: 'started',
                                                              elapsed: 1.0,
                                                              note: Socket.gethostname)
      expect(workflow_process).to have_received(:update).with(status: 'completed',
                                                              elapsed: Float,
                                                              note: 'some note to pass back to workflow')
    end
  end

  context 'when skipped ReturnState with a note' do
    let(:return_state) { LyberCore::ReturnState.new(status: 'skipped', note: 'some note to pass back to workflow') }

    it "updates workflow to 'skipped' and sets a custom note" do
      robot.perform(druid)
      expect(logger).to have_received(:info).with(/#{druid} processing/)
      expect(logger).to have_received(:info).with('work done!')

      expect(workflow_process).to have_received(:update).with(status: 'skipped',
                                                              elapsed: Float,
                                                              note: 'some note to pass back to workflow')
    end
  end

  context 'when there is a problem with the work' do
    let(:exception) { StandardError.new('work error') }

    it "updates workflow to 'error'" do
      robot.perform(druid)
      expect(logger).to have_received(:error).with(/work error/)
      expect(workflow_process).to have_received(:update_error).with(error_msg: /work error/,
                                                                    error_text: Socket.gethostname)
    end
  end

  context 'when there is a retriable problem with the work' do
    let(:exception) { NotImplementedError.new('retriable work error') }

    it "updates workflow to 'retrying'" do
      expect { robot.perform(druid) }.to raise_error(NotImplementedError)
      expect(logger).to have_received(:error).with(/retriable work error/)
      expect(workflow_process).to have_received(:update).with(status: 'retrying',
                                                              elapsed: 1.0,
                                                              note: nil)
    end
  end

  context 'when workflow status is not queued' do
    before do
      allow(process_response).to receive(:status).and_return('completed')
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

      expect(workflow_process).to have_received(:update).with(status: 'completed',
                                                              elapsed: Float,
                                                              note: Socket.gethostname)
    end
  end

  context 'when ReturnState is noop' do
    let(:return_state) { LyberCore::ReturnState.new(status: 'noop') }

    it 'only updates workflow for start' do
      robot.perform(druid)
      expect(workflow_process).to have_received(:update).once
    end
  end

  context 'when sidekiq retries is exhausted' do
    let(:job) do
      {
        'queue' => 'default',
        'class' => 'TestRobot',
        'args' => [druid],
        'error_message' => 'work error'
      }
    end

    let(:exception) { StandardError.new('work error') }

    it "updates workflow to 'error'" do
      TestRobot.sidekiq_retries_exhausted_block.call(job, exception)
      expect(workflow_process).to have_received(:update_error).with(error_msg: /work error/,
                                                                    error_text: Socket.gethostname)
    end
  end
end
