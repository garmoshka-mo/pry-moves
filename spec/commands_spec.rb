require_relative 'spec_helper'

describe 'PryMoves Commands' do

  include PryDebugger::Breakpoints

  it 'should make one step next' do
    breakpoints [
      [nil, 'basic next stop'],
      ['n', 'next step'],
    ]
    Playground.new.basic_next
  end

  it 'should step into func' do
    breakpoints [
      [nil, 'step_into stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line']
    ]
    Playground.new.step_into
  end

end
