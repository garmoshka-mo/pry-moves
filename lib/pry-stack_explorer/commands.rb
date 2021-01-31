module PryStackExplorer
  module FrameHelpers
    private

    # @return [PryStackExplorer::FrameManager] The active frame manager for
    #   the current `Pry` instance.
    def frame_manager
      PryStackExplorer.frame_manager(_pry_)
    end

    # @return [Array<PryStackExplorer::FrameManager>] All the frame
    #   managers for the current `Pry` instance.
    def frame_managers
      PryStackExplorer.frame_managers(_pry_)
    end

    # @return [Boolean] Whether there is a context to return to once
    #   the current `frame_manager` is popped.
    def prior_context_exists?
      frame_managers.count > 1 || frame_manager.prior_binding
    end

    # Return a description of the frame (binding).
    # This is only useful for regular old bindings that have not been
    # enhanced by `#of_caller`.
    # @param [Binding] b The binding.
    # @return [String] A description of the frame (binding).
    def frame_description(b)
      b_self = b.eval('self')
      b_method = b.eval('__method__')

      if b_method && b_method != :__binding__ && b_method != :__binding_impl__
        b_method.to_s
      elsif b_self.instance_of?(Module)
        "<module:#{b_self}>"
      elsif b_self.instance_of?(Class)
        "<class:#{b_self}>"
      else
        "<main>"
      end
    end

    # Return a description of the passed binding object. Accepts an
    # optional `verbose` parameter.
    # @param [Binding] b The binding.
    # @param [Boolean] verbose Whether to generate a verbose description.
    # @return [String] The description of the binding.
    def frame_info(b, verbose = false)
      b_self = b.eval('self')
      type = b.frame_type ? "[#{b.frame_type}]".ljust(9) : ""
      desc = b.frame_description ? "#{b.frame_description}" : "#{frame_description(b)}"
      sig = PryMoves::Helpers.method_signature b

      self_clipped = "#{Pry.view_clip(b_self)}"
      path = "@ #{b.eval('__FILE__')}:#{b.eval('__LINE__')}"

      if !verbose
        "#{type} #{desc} #{sig}"
      else
        "#{type} #{desc} #{sig}\n      in #{self_clipped} #{path}"
      end
    end

    def find_frame_by_regex(regex, up_or_down)
      frame_index = find_frame_by_block(up_or_down) do |b|
        (b.eval('"#{__FILE__}:#{__LINE__}"') =~ regex) or
          (b.eval("__method__").to_s =~ regex)
      end

      frame_index || raise(Pry::CommandError, "No frame that matches #{regex.source} found")
    end

    def find_frame_by_block(up_or_down)
      start_index = frame_manager.binding_index

      if up_or_down == :down
        enum = start_index == 0 ? [].each :
            frame_manager.bindings[0..start_index - 1].reverse_each
      else
        enum = frame_manager.bindings[start_index + 1..-1]
      end

      new_frame = enum.find do |b|
        yield(b)
      end

      frame_manager.bindings.index(new_frame)
    end

    def find_frame_by_direction(dir, step_into_vapid: false)
      PryMoves.show_vapid_frames = true if step_into_vapid
      frame_index = find_frame_by_block(dir) do |b|
          PryMoves.show_vapid_frames or
            not frame_manager.bindings.vapid?(b)
        end

      frame_index ||
        raise(Pry::CommandError, "At #{dir == :up ? 'top' : 'bottom'} of stack, cannot go further")
    end

    def move(direction, param)
      raise Pry::CommandError, "Nowhere to go" unless frame_manager

      if param == '+' or param.nil?
        index = find_frame_by_direction direction, step_into_vapid: param == '+'
        frame_manager.change_frame_to index
      else
        index = find_frame_by_regex(Regexp.new(param), direction)
        frame_manager.change_frame_to index
      end
    end
  end


  Commands = Pry::CommandSet.new do
    create_command "up", "Go up to the caller's context." do
      include FrameHelpers

      banner <<-BANNER
        Usage: up [OPTIONS]
          Go up to the caller's context. Accepts optional numeric parameter for how many frames to move up.
          Also accepts a string (regex) instead of numeric; for jumping to nearest parent method frame which matches the regex.
          e.g: up      #=> Move up normally
          e.g: up +    #=> Move up including vapid frames
          e.g: up meth #=> Jump to nearest parent stack frame whose method matches /meth/ regex, i.e `my_method`.
      BANNER

      def process
        move :up, args.first
      end
    end

    create_command "down", "Go down to the callee's context." do
      include FrameHelpers

      banner <<-BANNER
        Usage: down [OPTIONS]
          Go down to the callee's context. Accepts optional numeric parameter for how many frames to move down.
          Also accepts a string (regex) instead of numeric; for jumping to nearest child method frame which matches the regex.
          e.g: down      #=> Move down normally
          e.g: down +    #=> Move down including vapid frames
          e.g: down meth #=> Jump to nearest child stack frame whose method matches /meth/ regex, i.e `my_method`.
      BANNER

      def process
        move :down, args.first
      end
    end

    create_command "top", "Top" do
      include FrameHelpers
      def process
        frame_manager.change_frame_to frame_manager.bindings.size - 1
      end
    end

    create_command "bottom", "Bottom" do
      include FrameHelpers
      def process
        frame_manager.change_frame_to 0
      end
    end

    create_command "frame", "Switch to a particular frame." do
      include FrameHelpers

      banner <<-BANNER
        Usage: frame [OPTIONS]
          Switch to a particular frame. Accepts numeric parameter (or regex for method name) for the target frame to switch to (use with show-stack).
          Negative frame numbers allowed. When given no parameter show information about the current frame.

          e.g: frame 4         #=> jump to the 4th frame
          e.g: frame meth      #=> jump to nearest parent stack frame whose method matches /meth/ regex, i.e `my_method`
          e.g: frame -2        #=> jump to the second-to-last frame
          e.g: frame           #=> show information info about current frame
      BANNER

      def process
        if !frame_manager
          raise Pry::CommandError, "nowhere to go!"
        else

          if args[0] =~ /\d+/
            frame_manager.change_frame_to args[0].to_i
          elsif match = /^([A-Z]+[^#.]*)(#|\.)(.+)$/.match(args[0])
            new_frame_index = find_frame_by_object_regex(Regexp.new(match[1]), Regexp.new(match[3]), :up)
            frame_manager.change_frame_to new_frame_index
          elsif args[0] =~ /^[^-].*$/
            new_frame_index = find_frame_by_regex(Regexp.new(args[0]), :up)
            frame_manager.change_frame_to new_frame_index
          else
            output.puts "##{frame_manager.binding_index} #{frame_info(target, true)}"
          end
        end
      end
    end

    create_command "show-stack", "Show all frames" do
      include FrameHelpers

      banner <<-BANNER
        Usage: show-stack [OPTIONS]
          Show all accessible stack frames.
          e.g: show-stack -v
      BANNER

      def options(opt)
        opt.on :v, :verbose, "Include extra information."
        opt.on :H, :head, "Display the first N stack frames (defaults to 10).", :optional_argument => true, :as => Integer, :default => 10
        opt.on :T, :tail, "Display the last N stack frames (defaults to 10).", :optional_argument => true, :as => Integer, :default => 10
        opt.on :c, :current, "Display N frames either side of current frame (default to 5).", :optional_argument => true, :as => Integer, :default => 5
      end

      def memoized_info(index, b, verbose)
        frame_manager.user[:frame_info] ||= Hash.new { |h, k| h[k] = [] }

        if verbose
          frame_manager.user[:frame_info][:v][index]      ||= frame_info(b, verbose)
        else
          frame_manager.user[:frame_info][:normal][index] ||= frame_info(b, verbose)
        end
      end

      private :memoized_info

      # @return [Array<Fixnum, Array<Binding>>] Return tuple of
      #   base_frame_index and the array of frames.
      def selected_stack_frames
        if opts.present?(:head)
          [0, frame_manager.bindings[0..(opts[:head] - 1)]]

        elsif opts.present?(:tail)
          tail = opts[:tail]
          if tail > frame_manager.bindings.size
            tail = frame_manager.bindings.size
          end

          base_frame_index = frame_manager.bindings.size - tail
          [base_frame_index, frame_manager.bindings[base_frame_index..-1]]

        elsif opts.present?(:current)
          first_frame_index = frame_manager.binding_index - (opts[:current])
          first_frame_index = 0 if first_frame_index < 0
          last_frame_index = frame_manager.binding_index + (opts[:current])
          [first_frame_index, frame_manager.bindings[first_frame_index..last_frame_index]]

        else
          [0, frame_manager.bindings]
        end
      end

      private :selected_stack_frames

      def process
        if !frame_manager
          output.puts "No caller stack available!"
        else
          content = ""
          content << "\n#{text.bold("Showing all accessible frames in stack (#{frame_manager.bindings.size} in total):")}\n--\n"

          base_frame_index, frames = selected_stack_frames
          frames.each_with_index do |b, index|
            i = index + base_frame_index
            if i == frame_manager.binding_index
              content << "=> ##{i} #{memoized_info(i, b, opts[:v])}\n"
            else
              content << "   ##{i} #{memoized_info(i, b, opts[:v])}\n"
            end
          end

          stagger_output content
        end
      end

    end
  end
end
