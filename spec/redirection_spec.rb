require_relative 'spec_helper'

describe 'redirection' do

  it 'redirects with debug_redirect' do
    breakpoints [
      [nil, 'redirection host'],
      ['n', nil],
      ['s', 'inside of level_a'],
      ['c', 'stop in level_c']
    ]
    Playground.new.redirection_host
  end

  it 'redirects within named step in' do
    breakpoints [
      [nil, 'redirection host'],
      ['s with_redirection', 'inside of level_a'],
      ['c', 'stop in level_c']
    ]
    Playground.new.redirection_host
  end

  it "doesn't redirect for step in everywhere" do
    breakpoints [
      [nil, 'redirection host'],
      ['n', nil],
      ['s +', 'at method_with_redirection'],
      ['c', 'stop in level_c']
    ]
    Playground.new.redirection_host
  end

  it "instantly redirects binding.pry" do
    breakpoints [
      [nil, 'some internal line']
    ]
    Playground.new.instant_redirection
  end

end