require_relative 'spec_helper'

describe 'PryMoves commands' do

  # todo: test sugars: method_missing, etc...

  it 'should make one move next' do
    breakpoints [
      [nil, 'basic next stop'],
      ['n', 'next step'],
    ]
    Playground.new.basic_next
  end

  it 'should stop on second binding.pry' do
    breakpoints [
      [nil, 'first stop'],
      ['c', 'second stop'],
    ]
    Playground.new.continue
  end

  it 'should walk over stack' do
    breakpoints [
      [nil, 'step_into stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line'],
      ['up', 'point to step inside'],
      ['up', 'spec example beginning' ],
      #['up', {output_includes: 'top of stack'} ],
      ['down', 'point to step inside'],
      ['down', 'some internal line'],
      ['down', {output_includes: 'bottom of stack'} ],
    ]
    Playground.new.step_into # spec example beginning
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

  it 'should next breakpoint' do
    breakpoints [
      [nil, 'method_with_breakpoints host'],
      ['b', 'breakpoint'],
      ['n', 'after breakpoint'],
      ['b', 'breakpoint 2']
    ]
    Playground.new.method_with_breakpoints
  end

end
