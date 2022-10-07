# frozen_string_literal: true

describe LyberCore::Robot::ReturnState do
  it 'sets the completed state by default' do
    return_state = described_class.new
    expect(return_state.status).to eq 'completed'
  end

  it 'allows other return states to be set' do
    return_state = described_class.new(status: 'completed')
    expect(return_state.status).to eq 'completed'
    expect(return_state.note).to eq ''
    return_state = described_class.new
    return_state.status = 'skipped'
    expect(return_state.status).to eq 'skipped'
    return_state = described_class.new(status: 'skipped')
    expect(return_state.status).to eq 'skipped'
  end

  it 'allows a note to be set' do
    return_state = described_class.new(note: 'some note to be passed back to workflow')
    expect(return_state.status).to eq 'completed'
    expect(return_state.note).to eq 'some note to be passed back to workflow'
    return_state = described_class.new(status: 'skipped', note: 'some note to be passed back to workflow')
    expect(return_state.status).to eq 'skipped'
    expect(return_state.note).to eq 'some note to be passed back to workflow'
  end

  it 'does not care about the case or if it is symbol' do
    return_state = described_class.new(status: 'COMPLETED')
    expect(return_state.status).to eq 'completed'
    return_state = described_class.new(status: :skipped)
    expect(return_state.status).to eq 'skipped'
    return_state = described_class.new(status: 'Skipped')
    expect(return_state.status).to eq 'skipped'
  end

  it 'does not allow an invalid state to be set' do
    expect{ described_class.new(status: 'bogus') }.to raise_error(RuntimeError, 'invalid return state')
  end
end
