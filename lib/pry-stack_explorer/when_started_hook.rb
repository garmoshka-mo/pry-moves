module PryStackExplorer
  class WhenStartedHook
    include Pry::Helpers::BaseHelpers

    def call(target, options, _pry_)
      start_from_console = target.eval('__callee__').nil? &&
        target.eval('__FILE__') == '<main>' &&
        target.eval('__LINE__') == 0
      return if start_from_console

      options = {
        call_stack: true
      }.merge!(options)

      return unless options[:call_stack]
      initial_frame = options[:initial_frame]

      if options[:call_stack].is_a?(Array)
        bindings = options[:call_stack]
        initial_frame ||= 0
        unless valid_call_stack?(bindings)
          raise ArgumentError, ":call_stack must be an array of bindings"
        end
      else
        bindings = PryMoves::BindingsStack.new
        initial_frame ||= bindings.suggest_initial_frame_index
        # if Thread.current[:pry_moves_debug] and initial_frame > 0
        if initial_frame > 0
          PryMoves.messages << "⚠️  Frames hidden: #{initial_frame}"
        end
      end

      PryStackExplorer.create_and_push_frame_manager bindings, _pry_, initial_frame: initial_frame
    end

    private

    def valid_call_stack?(bindings)
      bindings.any? && bindings.all? { |v| v.is_a?(Binding) }
    end
  end
end
