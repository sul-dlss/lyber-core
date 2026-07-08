# frozen_string_literal: true

describe LyberCore::Workflow do
  let(:workflow) do
    described_class.new(object_client:, workflow_name: 'workflow', process: 'process', version:)
  end
  let(:version) { 2 }
  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id:, context:, status:, active_version?: active_version) }
  let(:workflow_response) do
    instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response,
                                                       process_for: process_response)
  end
  let(:active_version) { true }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, process: workflow_process, find: workflow_response) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: object_workflow) }
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: nil, update_error: nil) }
  let(:lane_id) { 'lane1' }
  let(:context) { { 'foo' => 'bar' } }
  let(:note) { 'note' }
  let(:status) { 'waiting' }

  describe '#start!' do
    it 'updates the status to started' do
      workflow.start!(note)
      expect(workflow_process).to have_received(:update).with(status: 'started', elapsed: 1.0, note:, version:)
    end
  end

  describe '#complete!' do
    let(:complete_status) { 'completed' }
    let(:elapsed) { 3.0 }

    it 'updates the status to provided status' do
      workflow.complete!(complete_status, elapsed, note)
      expect(workflow_process).to have_received(:update).with(status: complete_status, elapsed: 3.0, note:, version:)
    end
  end

  describe '#retrying!' do
    it 'updates the status to retrying' do
      workflow.retrying!
      expect(workflow_process).to have_received(:update).with(status: 'retrying', elapsed: 1.0, note: nil, version:)
    end
  end

  describe '#error!' do
    let(:error_msg) { 'Doh' }
    let(:error_text) { 'Whelp, that was bad.' }

    it 'updates the status to an error' do
      workflow.error!(error_msg, error_text)
      expect(workflow_process).to have_received(:update_error).with(error_msg:, error_text:, version:)
    end
  end

  describe '#skip!' do
    it 'updates the status to skipped' do
      workflow.skip!(note)
      expect(workflow_process).to have_received(:update).with(status: 'skipped', elapsed: 0, note:, version:)
    end
  end

  describe '#context' do
    it 'returns the context hash' do
      expect(workflow.context).to eq(context)
    end
  end

  describe '#lane_id' do
    it 'returns the lane_id' do
      expect(workflow.lane_id).to eq(lane_id)
    end
  end

  describe '#status' do
    it 'returns the status' do
      expect(workflow.status).to eq(status)
    end
  end

  describe '#version' do
    it 'returns the version' do
      expect(workflow.version).to eq(version)
    end
  end

  describe '#active_version?' do
    it 'delegates to the process for the given version' do
      expect(workflow.active_version?).to be true
      expect(workflow_response).to have_received(:process_for).with(name: 'process', version:)
    end

    context 'when the process is not for the active version' do
      let(:active_version) { false }

      it 'returns false' do
        expect(workflow.active_version?).to be false
      end
    end
  end
end
