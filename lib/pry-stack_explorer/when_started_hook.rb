module PryStackExplorer
  class WhenStartedHook
    include Pry::Helpers::BaseHelpers

    def call(target, options, _pry_)
      start_from_console = target.eval('__callee__').nil? &&
        target.eval('__FILE__') == '<main>' &&
        target.eval('__LINE__') == 0
      return if start_from_console

      options = {
        :call_stack    => true,
        :initial_frame => 0
      }.merge!(options)

      return if !options[:call_stack]

      if options[:call_stack].is_a?(Array)
        bindings = options[:call_stack]
        unless valid_call_stack?(bindings)
          raise ArgumentError, ":call_stack must be an array of bindings"
        end
      else
        bindings = PryMoves::BindingsStack.new binding
        options[:initial_frame] = bindings.initial_frame_index
        # if Thread.current[:pry_moves_debug] and options[:initial_frame] > 0
        if options[:initial_frame] > 0
          PryMoves.messages << "⚠️  Frames hidden: #{options[:initial_frame]}"
        end
      end

      PryStackExplorer.create_and_push_frame_manager bindings, _pry_, initial_frame: options[:initial_frame]
    end

    private

    def valid_call_stack?(bindings)
      bindings.any? && bindings.all? { |v| v.is_a?(Binding) }
    end
  end
end
