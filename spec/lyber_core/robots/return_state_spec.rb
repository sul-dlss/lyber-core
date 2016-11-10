require 'spec_helper'

describe LyberCore::Robot::ReturnState do
  
  it "should set the completed state by default" do
    return_state=LyberCore::Robot::ReturnState.new
    expect(return_state.status).to eq 'completed'
  end

  it "should allow other return states to be set" do
    return_state=LyberCore::Robot::ReturnState.new('completed')
    expect(return_state.status).to eq 'completed'
    return_state=LyberCore::Robot::ReturnState.new
    return_state.status='skipped'
    expect(return_state.status).to eq 'skipped'
    return_state=LyberCore::Robot::ReturnState.new('skipped')
    expect(return_state.status).to eq 'skipped'
  end
  
  it "should not care about the case or if it is symbol" do
    return_state=LyberCore::Robot::ReturnState.new('COMPLETED')
    expect(return_state.status).to eq 'completed'
    return_state=LyberCore::Robot::ReturnState.new(:skipped)
    expect(return_state.status).to eq 'skipped'
  end

  it "should not allow an invalid state to be set" do
    expect{LyberCore::Robot::ReturnState.new('bogus')}.to raise_error(RuntimeError,'invalid return state')
  end
    
end