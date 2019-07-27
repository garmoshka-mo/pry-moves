require_relative 'spec_helper'

describe 'whereami' do

  it 'executes whereami at each step when debugging with binding.pry' do
    expect_any_instance_of(Pry::Command::Whereami).to receive(:build_output).and_call_original
    breakpoints [
      [nil, 'debugging with binding.pry'],
    ]

    binding.pry # debugging with binding.pry
  end

  it 'suppresses whereami output when started via console (via Pry.start) rather than binding.pry or Object#pry' do
    expect_any_instance_of(Pry::Command::Whereami).not_to receive(:build_output)
    breakpoints [
      [nil, ''],
    ]

    Pry.start # simulate a console initiating pry
  end

end
