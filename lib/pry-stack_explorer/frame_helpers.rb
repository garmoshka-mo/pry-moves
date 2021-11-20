module PryStackExplorer; end
module PryStackExplorer::FrameHelpers
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
    sig = PryMoves::Formatter.new.method_signature b

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
    frame_index = find_frame_by_block(dir) do |b|
      step_into_vapid or not b.hidden
    end

    if !frame_index and !step_into_vapid
      frame_index = find_frame_by_block(dir) {true}
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