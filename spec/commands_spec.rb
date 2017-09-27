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

  it 'should step into func and walk over stack' do
    breakpoints [
      [nil, 'step_into stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line'],
      ['up', 'point to step inside'],
      ['up', nil ],
      ['up', {out_include: 'top of stack'} ],
      ['down', nil ],
      ['down', 'some internal line'],
      ['down', {out_include: 'bottom of stack'} ],
    ]
    Playground.new.step_into
  end

  it 'should go next over recursion calls' do
    breakpoints [
      [nil, nil],
      ['n', 'next step'],
      ['n', 'should stop here after 2 next-s'],
      ['depth', {out: '=> 0'}],
    ]
    Playground.new.recursion
  end

end
