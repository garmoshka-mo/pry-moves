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

  it 'should step down to hidden frame and resume there' do
    breakpoints [
      [nil, 'at root'],
      ['down', 'hidden stop'],
      ['n', 'hidden_stop for next'],
      ['s', 'hidden_stop for step']
    ]
    Playground.new.hidden_stop # at root
  end

  it 'should skip hidden method' do
    breakpoints [
      [nil, 'stop in skip_test'],
      ['n', 'next step'],
      ['s', 'at not_skipped_method']
    ]
    Playground.new.skip_test
  end

end