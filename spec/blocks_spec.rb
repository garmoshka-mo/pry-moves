require_relative 'spec_helper'

describe 'blocks' do

  it 'should go next over blocks' do
    breakpoints [
      [nil, 'stop in zaloop'],
      ['n', 'iterator line'],
      # repeat commands
      ['', 'inside block'],
      ['', nil],

      ['s', 'stop in zaloop'],
      ['n', nil],
      ['', 'inside block'],
      ['pass', {output: '=> 0'}],

      ['f', 'iterator line'],
      ['f', 'after sub-zaloop'],
      ['pass', {output: '=> :root'}],

      ['f', 'after block'],
      ['pass', {output: '=> :root'}],
    ]
    Playground.new.zaloop
  end

  it 'should finish simple block' do
    breakpoints [
      [nil, 'stop in nested_block'],
      ['n', 'iterator line'],
      ['', 'inside block'],
      ['f', 'after block']
    ]
    Playground.new.nested_block
  end

  it 'should finish block with sub-calls' do
    breakpoints [
      [nil, 'stop in zaloop'],
      ['n', 'iterator line'],
      ['', 'inside block'],
      ['f', 'after block'],
      ['pass', {output: '=> :root'}],
    ]
    Playground.new.zaloop
  end

  it 'should iterate over native block' do
    breakpoints [
      [nil, 'stop in native_block'],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['i', {output: '=> 0'}],
      ['iterate', 'inside block'],
      ['i', {output: '=> 1'}],
      ['iterate', 'after block'],
    ]
    Playground.new.native_block
  end

  it 'should iterate over nested block' do
    breakpoints [
      [nil, 'stop in nested_block'],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['i', {output: '=> 0'}],
      ['iterate', 'inside block'],
      ['i', {output: '=> 1'}],
      ['iterate', 'after block'],
    ]
    Playground.new.nested_block
  end

  it 'should return during iterating native block' do
    breakpoints [
      [nil, 'stop in native_block'],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['iterate', 'iterator line'],
      ['n', 'exit']
    ]
    Playground.new.native_block early_return: true
    :exit # exit
  end

  it 'should return during iterating nested block' do
    breakpoints [
      [nil, 'stop in nested_block'],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['iterate', 'iterator line'],
      ['n', 'exit']
    ]
    Playground.new.nested_block early_return: true
    :exit # exit
  end

  it 'should iterate over one-line in block' do
    breakpoints [
      [nil, 'stop in one_line_in_block'],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['i', {output: '=> 0'}],
      ['n', 'inside block'],
      ['i', {output: '=> 1'}],
      ['n', 'after block'],
    ]
    Playground.new.one_line_in_block
  end

  it 'should skip one-line block' do
    breakpoints [
      [nil, 'stop in one_line_block'],
      ['n', 'iterator line'],
      ['n', 'after block']
    ]
    Playground.new.one_line_block
  end

  it 'should skip parentheses in loop' do
    breakpoints [
      [nil, 'stop in parentheses_in_loop'],
      ['n', nil],
      ['n', 'iterator line'],
      ['n', 'inside block'],
      ['n', 'iterator line'],
      ['n', 'after block']
    ]
    Playground.new.parentheses_in_loop
  end
  
end