module PryStackExplorer
  class WhenStartedHook
    include Pry::Helpers::BaseHelpers

    def caller_bindings(target)
      bindings = binding.callers
      bindings = remove_internal_frames(bindings)
      mark_vapid_frames(bindings)
      bindings
    end

    def call(target, options, _pry_)
      target ||= _pry_.binding_stack.first if _pry_
      options = {
        :call_stack    => true,
        :initial_frame => 0
      }.merge!(options)

      return if !options[:call_stack]

      if options[:call_stack].is_a?(Array)
        bindings = options[:call_stack]

        if !valid_call_stack?(bindings)
          raise ArgumentError, ":call_stack must be an array of bindings"
        end
      else
        bindings = caller_bindings(target)
      end

      PryStackExplorer.create_and_push_frame_manager bindings, _pry_, :initial_frame => options[:initial_frame]
    end

    private

    def mark_vapid_frames(bindings)
      stepped_out = false
      actual_file, actual_method = nil, nil

      bindings.each do |binding|
        if stepped_out
          if actual_file == binding.eval("__FILE__") and actual_method == binding.eval("__method__")
            stepped_out = false
          else
            binding.local_variable_set :vapid_frame, true
          end
        elsif binding.frame_type == :block
          stepped_out = true
          actual_file = binding.eval("__FILE__")
          actual_method = binding.eval("__method__")
        end

        if binding.local_variable_defined? :hide_from_stack
          binding.local_variable_set :vapid_frame, true
        end
      end
    end

    # remove internal frames related to setting up the session
    def remove_internal_frames(bindings)
      i = top_internal_frame_index(bindings)
      # DEBUG:
      #bindings.each_with_index do |b, index|
      #  puts "#{index}: #{b.eval("self.class")} #{b.eval("__method__")}"
      #end
      #puts "FOUND top internal frame: #{bindings.size} => #{i}"

      bindings.drop i+1
    end

    def top_internal_frame_index(bindings)
      bindings.rindex do |b|
        if b.frame_type == :method
          self_, method = b.eval("self"), b.eval("__method__")
          self_.equal?(Pry) && method == :start ||
            self_.class == Binding && method == :pry ||
            self_.class == PryMoves::Tracer && method == :tracing_func
        end
      end
    end

    def valid_call_stack?(bindings)
      bindings.any? && bindings.all? { |v| v.is_a?(Binding) }
    end
  end
end
