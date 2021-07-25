require_relative 'spec_helper'

describe 'backtrace' do

  it 'should backtrace' do
    breakpoints [
      [nil, 'stop in level_c'],
      ['bt', lambda{|b, output|
        lines = output.split("\n").reverse
        expect(lines[0]).to end_with 'level_c(param=? nil)'
        expect(lines[1]).to end_with 'frames hidden: 1'
        expect(lines[2]).to end_with 'level_a()'
        expect(lines[3]).to include 'Playground'
        expect(lines[4]).to end_with ':block'
        expect(lines[5]).to include 'RSpec::ExampleGroups'
        expect(lines.count).to be 7
      }],
      ['bt hidden', lambda{|b, output|
        lines = output.split("\n").reverse
        # show hidden frame
        expect(lines[1]).to end_with 'level_b()'
        expect(lines.count).to be 11
      }],
      ['up', lambda{|b, output|
        lines = output.split("\n").reverse
        expect(lines[1]).to end_with 'level_b # inside of level_a'
      }],
    ]
    Playground.new.level_a
  end

end
