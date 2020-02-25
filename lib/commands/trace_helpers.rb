module PryMoves::TraceHelpers

  def redirect_step?(binding_)
    return false unless binding_.local_variable_defined? :debug_redirect

    debug_redirect = binding_.local_variable_get(:debug_redirect)
    @step_into_funcs = [debug_redirect.to_s] if debug_redirect
    true
  end

  def debug_info(file, line, id)
    puts "📽  Action:#{@action}; recur:#{@call_depth}; #{@method[:file]}:#{file}"
    puts "#{id} #{@method[:start]} > #{line} > #{@method[:end]}"
  end

  def exit_from_method
    @pry_start_options[:exit_from_method] = true
    true
  end


  def current_frame_digest(upward: 0)
    # binding_ from tracing_func doesn't have @iseq,
    # therefore binding should  be re-retrieved using 'binding_of_caller' lib
    frame_digest(binding.of_caller(4 + upward))
  end

  def frame_digest(binding_)
    #puts "frame_digest for: #{binding_.eval '__callee__'}"
    Digest::MD5.hexdigest binding_.instance_variable_get('@iseq').disasm
  end

  def current_frame_type(upward: 0)
    # binding_ from tracing_func doesn't have @iseq,
    # therefore binding should  be re-retrieved using 'binding_of_caller' lib
    frame_type(binding.of_caller(4 + upward))
  end

  def frame_type(binding_)
    line = binding_.instance_variable_get('@iseq').disasm.split("\n").first
    m = line.match /\== disasm: #<ISeq:([\w ]+)@/
    if m
      str = m[1]
      if str.start_with? 'block in '
        :block
      else
        :method
      end
    else
      :unknown
    end
  end

end