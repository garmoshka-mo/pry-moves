require 'pry'
require_relative 'mocks'
require_relative 'pry_debugger'
require_relative '../playground/playground.rb'

describe 'PryMoves Commands' do

  it 'sepa' do
    puts :a
    binding.pry
    puts :a
  end

  it 'should work' do
    PryDebugger.reset

    PryDebugger.on_next_breakpoint do |binding_|
      puts :first
      puts binding_.eval('__FILE__')
      puts binding_.eval('__LINE__')

      #'bt'
      'up'
    end

    PryDebugger.on_next_breakpoint do |binding_|
      puts :second
      puts binding_.eval('__FILE__')
      puts binding_.eval('__LINE__')

      'n'
    end

    PryDebugger.on_next_breakpoint do |binding_|
      puts :third
      puts binding_.eval('__FILE__')
      puts binding_.eval('__LINE__')

      'c'
    end

    i = Playground.new
    i.basic_breakpoint
    puts :ok
  end

end
