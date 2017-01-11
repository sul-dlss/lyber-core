require 'spec_helper'

describe LyberCore::Robot::ReturnState do
  
  it "should set the completed state by default" do
    return_state=LyberCore::Robot::ReturnState.new
    expect(return_state.status).to eq 'completed'
  end

  it "should allow other return states to be set" do
    return_state=LyberCore::Robot::ReturnState.new(status: 'completed')
    expect(return_state.status).to eq 'completed'
    expect(return_state.note).to eq ''
    return_state=LyberCore::Robot::ReturnState.new
    return_state.status='skipped'
    expect(return_state.status).to eq 'skipped'
    return_state=LyberCore::Robot::ReturnState.new(status: 'skipped')
    expect(return_state.status).to eq 'skipped'
  end
  
  it "should allow a note to be set" do
    return_state=LyberCore::Robot::ReturnState.new(note: 'some note to be passed back to workflow')
    expect(return_state.status).to eq 'completed'
    expect(return_state.note).to eq 'some note to be passed back to workflow'
    return_state=LyberCore::Robot::ReturnState.new(status: 'skipped', note: 'some note to be passed back to workflow')
    expect(return_state.status).to eq 'skipped'
    expect(return_state.note).to eq 'some note to be passed back to workflow'
  end
  
  it "should not care about the case or if it is symbol" do
    return_state=LyberCore::Robot::ReturnState.new(status: 'COMPLETED')
    expect(return_state.status).to eq 'completed'
    return_state=LyberCore::Robot::ReturnState.new(status: :skipped)
    expect(return_state.status).to eq 'skipped'
    return_state=LyberCore::Robot::ReturnState.new(status: 'Skipped')
    expect(return_state.status).to eq 'skipped'
  end

  it "works with ReturnState constants" do
    return_state=LyberCore::Robot::ReturnState.SKIPPED
    expect(return_state.status).to eq 'skipped'
    return_state=LyberCore::Robot::ReturnState.COMPLETED
    expect(return_state.status).to eq 'completed'
    return_state=LyberCore::Robot::ReturnState.WAITING
    expect(return_state.status).to eq 'waiting'
  end
  
  it "should not allow an invalid state to be set" do
    expect{LyberCore::Robot::ReturnState.new(status: 'bogus')}.to raise_error(RuntimeError,'invalid return state')
  end
    
end
