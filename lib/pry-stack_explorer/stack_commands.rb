require_relative 'frame_helpers.rb'

module PryStackExplorer

  COMMANDS = Pry::CommandSet.new do

    block_command '%', 'Print current stack frame' do
      run 'whereami'
    end

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
        return if PryMoves::Vars.var_precedence "top", target
        frame_manager.change_frame_to frame_manager.bindings.size - 1
      end
    end

    create_command "bottom", "Bottom" do
      include FrameHelpers
      def process
        return if PryMoves::Vars.var_precedence "bottom", target
        frame_manager.change_frame_to 0
      end
    end
    alias_command 'bm', 'bottom'

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
        return if PryMoves::Vars.var_precedence "frame", target
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
