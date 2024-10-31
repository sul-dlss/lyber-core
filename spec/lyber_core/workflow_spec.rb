# frozen_string_literal: true

describe LyberCore::Workflow do
  let(:workflow) do
    described_class.new(workflow_service: workflow_client, druid: 'druid:123', workflow_name: 'workflow',
                        process: 'process')
  end
  let(:workflow_client) { instance_double(Dor::Workflow::Client, process: workflow_process, workflow_status: status) }
  let(:workflow_process) { instance_double(Dor::Workflow::Response::Process, lane_id:, context:) }
  let(:lane_id) { 'lane1' }
  let(:context) { { 'foo' => 'bar' } }
  let(:note) { 'note' }
  let(:status) { 'waiting' }

  before do
    allow(workflow_client).to receive(:update_status)
    allow(workflow_client).to receive(:update_error_status)
  end

  describe '#start!' do
    it 'updates the status to started' do
      workflow.start!(note)
      expect(workflow_client).to have_received(:update_status).with(druid: 'druid:123', workflow: 'workflow',
                                                                    process: 'process', status: 'started',
                                                                    elapsed: 1.0, note:)
    end
  end

  describe '#complete!' do
    let(:complete_status) { 'completed' }
    let(:elapsed) { 3.0 }

    it 'updates the status to provided status' do
      workflow.complete!(complete_status, elapsed, note)
      expect(workflow_client).to have_received(:update_status).with(druid: 'druid:123', workflow: 'workflow',
                                                                    process: 'process', status: complete_status,
                                                                    elapsed: 3.0, note:)
    end
  end

  describe '#retrying!' do
    it 'updates the status to retrying' do
      workflow.retrying!
      expect(workflow_client).to have_received(:update_status).with(druid: 'druid:123', workflow: 'workflow',
                                                                    process: 'process', status: 'retrying',
                                                                    elapsed: 1.0, note: nil)
    end
  end

  describe '#error!' do
    let(:error_msg) { 'Doh' }
    let(:error_text) { 'Whelp, that was bad.' }

    it 'updates the status to an error' do
      workflow.error!(error_msg, error_text)
      expect(workflow_client).to have_received(:update_error_status).with(druid: 'druid:123', workflow: 'workflow',
                                                                          process: 'process', error_msg:,
                                                                          error_text:)
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
end
