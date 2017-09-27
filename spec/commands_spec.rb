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
      ['up', {out_include: 'top of stack'} ],
      ['down', nil ],
      ['down', 'some internal line'],
      ['down', {out_include: 'bottom of stack'} ],
    ]
    Playground.new.step_into
  end

  it 'should go next over blocks' do
    breakpoints [
      [nil, 'stop in zaloop'],
      ['n', ''],
      # repeat commands
      ['', 'inside block'],
      ['', nil],

      ['s', 'stop in zaloop'],
      ['n', nil],
      ['', 'inside block'],
      ['pass', {out: '=> 0'}],

      ['f', 'after block'],
      ['pass', {out: '=> 0'}],

      ['f', 'post_yield'], # Тут хорошо бы, чтобы сразу шёл на "after block",
                           # но пока и не понятно, как это угадать
      ['f', 'after block'],
      ['pass', {out: '=> :root'}],
    ]
    Playground.new.zaloop
  end

  it 'should finish simple block' do
    breakpoints [
      [nil, 'stop in with_simple_block'],
      ['n', ''],
      ['', 'inside block'],
      ['f', 'after block']
    ]
    Playground.new.with_simple_block
  end

  it 'should finish block with sub-calls' do
    breakpoints [
      [nil, 'stop in zaloop'],
      ['n', ''],
      ['', 'inside block'],
      ['f', 'after block'],
      ['pass', {out: '=> :root'}],
    ]
    Playground.new.zaloop
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

  it 'should backtrace' do
    breakpoints [
      [nil, 'stop in level_c'],
      ['bt', lambda{|b, out|
        lines = out.split("\n").reverse
        expect(lines[0]).to end_with 'Playground#level_c() :method'
        expect(lines[1]).to end_with 'Playground#level_a() :method'
        expect(lines[2]).to include 'Playground:'
        expect(lines[3]).to end_with ':block'
        expect(lines[4]).to include 'RSpec::ExampleGroups'
        expect(lines.count).to be 5
      }],
      ['bt all', lambda{|b, out|
        lines = out.split("\n").reverse
        # show hidden frame
        expect(lines[1]).to end_with 'Playground#level_b() :method'
        expect(lines.count).to be 6
      }],
      ['bt 2', lambda{|b, out|
        lines = out.split("\n").reverse
        expect(lines[0]).to end_with 'Playground#level_c() :method'
        expect(lines[1]).to end_with 'Playground#level_a() :method'
        expect(lines[3]).to start_with 'Latest 2 lines'
        expect(lines.count).to be 4
      }],
    ]
    Playground.new.level_a
  end

  it 'should debug' do
    breakpoints [
      [nil, 'basic next stop'],
      ['debug level_a', 'inside of level_a'],
      ['n', 'basic next stop'],
    ]
    Playground.new.basic_next
  end


end
