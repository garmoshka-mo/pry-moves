require_relative 'spec_helper'

describe 'PryMoves commands' do

  it 'should make one step next' do
    breakpoints [
      [nil, 'basic next stop'],
      ['n', 'next step'],
    ]
    Playground.new.basic_next
  end

  it 'should stop on second breakpoint' do
    breakpoints [
      [nil, 'first stop'],
      ['c', 'second stop'],
    ]
    Playground.new.continue
  end

  it 'should step into func and walk over stack' do
    breakpoints [
      [nil, 'step_into stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line'],
      ['up', 'point to step inside'],
      ['up', nil ],
      ['up', {output_includes: 'top of stack'} ],
      ['down', nil ],
      ['down', 'some internal line'],
      ['down', {output_includes: 'bottom of stack'} ],
    ]
    Playground.new.step_into
  end

  it 'should skip hidden implementation' do
    breakpoints [
      [nil, 'skip_hidden_impl stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line']
    ]
    Playground.new.skip_hidden_impl
  end

  it 'should step into func by name' do
    breakpoints [
      [nil, 'stop in step_by_name'],
      ['s level_c', 'stop in level_c'],
      ['param', {output: '=> :target'}],
      ['n', nil],
    ]
    Playground.new.step_by_name
  end

  it 'should stop after inability to step into func by name' do
    breakpoints [
      [nil, 'stop in step_by_name'],
      ['s absent_function', 'after_step_by_name'],
    ]
    Playground.new.step_by_name_wrap
  end

  it 'should go next over recursion calls' do
    breakpoints [
      [nil, nil],
      ['n', 'next step'],
      ['n', 'should stop here after 2 next-s'],
      ['depth', {output: '=> 0'}],
    ]
    Playground.new.recursion
  end

  it 'should stop after finishing early return' do
    breakpoints [
      [nil, 'stop in level_c'],
      ['f', 'at early return'],
      ['f', 'after early return']
    ]
    Playground.new.early_return_wrap
  end

  it 'should debug' do
    breakpoints [
      [nil, 'basic next stop'],
      ['debug level_a', 'inside of level_a'],
      ['n', 'basic next stop']
    ]
    Playground.new.basic_next
  end

end
