module PryMoves::Recursion

  class Tracker

    attr_reader :loops

    def initialize
      @history = []
      @loops = 0
      @missing = 0
      @currently_missing = []
      @missing_lines = []
    end

    def track file, line_num, bt_index, binding_index
      line = "#{file}:#{line_num}"
      if @last_index
        check_recursion line, bt_index, binding_index
      elsif (prev_index = @history.rindex line)
        @loops += 1
        @last_index = prev_index
        @recursion_size = 1
      else
        @history << line
        @last_index = nil
      end

      @repetitions_start ||= bt_index if @loops == 2
    end

    def check_recursion line, bt_index, binding_index
      prev_index = @history.rindex line
      if prev_index == @last_index
        @loops += 1
        @missing = 0
        @recursion_size = 0
        @missing_lines.concat @currently_missing
        @repetitions_end = bt_index
      elsif prev_index && prev_index > @last_index
        @last_index = prev_index + 1
        @recursion_size += 1
        # todo: finish tracking and debug multi-line recursions
      elsif @missing <= @recursion_size
        @missing += 1
        @currently_missing << binding_index
        false
      else
        # @missing_lines = nil
        # @last_index = nil
        @is_finished = true
        false
      end
    end

    def finished?
      @is_finished
    end

    def good?
      @repetitions_start and @repetitions_end
    end

    def apply result
      label = "♻️  recursion with #{@loops} loops"
      label += " Ⓜ️  #{@missing} missing lines #{@missing_lines}" if @missing_lines.present?
      label = "...(#{label})..."
      # puts "#{@repetitions_start}..#{@repetitions_end}"
      result[@repetitions_start..@repetitions_end] = [label]
    end

  end

  class Holder < Array

    def initialize(*args)
      super
      new_tracker
    end

    def new_tracker
      @tracker = Tracker.new
    end

    def track *args
      @tracker.track *args
      if @tracker.finished?
        self << @tracker if @tracker.good?
        new_tracker
      end
    end

  end

end
