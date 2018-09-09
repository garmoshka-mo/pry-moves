require_relative 'spec_helper'

describe 'redirection' do

  it 'redirects' do
    breakpoints [
      [nil, 'redirection host'],
      ['n', nil],
      ['s', 'inside of level_a']
    ]
    Playground.new.redirection_host
  end

  it 'redirects correctly after named step in' do
    breakpoints [
      [nil, 'redirection host'],
      ['n', nil],
      ['s with_redirection', 'inside of level_a']
    ]
    Playground.new.redirection_host
  end

end