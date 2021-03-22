require_relative 'spec_helper'

describe 'step' do

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

  it 'should skip hidden frames' do
    breakpoints [
      [nil, 'skip_hidden_impl stop'],
      ['s', 'point to step inside'],
      ['s', 'some internal line']
    ]
    Playground.new.skip_hidden_impl
  end

  it 'should skip hidden method' do
    breakpoints [
      [nil, 'stop in skip_level_a'],
      ['n', 'next step'],
      ['s', 'inside of level_a']
    ]
    Playground.new.skip_level_a
  end

  
end