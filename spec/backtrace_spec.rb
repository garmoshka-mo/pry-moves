require_relative 'spec_helper'

describe 'backtrace' do

  it 'should backtrace' do
    breakpoints [
      [nil, 'stop in level_c'],
      ['bt', lambda{|b, out|
        lines = out.split("\n").reverse
        expect(lines[0]).to end_with 'level_c(param=?)'
        expect(lines[1]).to end_with 'level_a()'
        expect(lines[2]).to include 'Playground:'
        expect(lines[3]).to end_with ':block'
        expect(lines[4]).to include 'RSpec::ExampleGroups'
        expect(lines.count).to be 5
      }],
      ['bt all', lambda{|b, out|
        lines = out.split("\n").reverse
        # show hidden frame
        expect(lines[1]).to end_with 'level_b()'
        expect(lines.count).to be 6
      }],
      ['bt 2', lambda{|b, out|
        lines = out.split("\n").reverse
        expect(lines[0]).to end_with 'level_c(param=?)'
        expect(lines[1]).to end_with 'level_a()'
        expect(lines[3]).to start_with 'Latest 2 lines'
        expect(lines.count).to be 4
      }],
    ]
    Playground.new.level_a
  end

end
