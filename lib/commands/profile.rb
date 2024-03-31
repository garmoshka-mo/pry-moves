class PryMoves::Profile < PryMoves::TraceCommand

  def init(binding_)
    @start_line = binding_.eval('__LINE__')
  end

  def trace(event, file, line, method, binding_)
    return unless file.start_with? PryMoves.project_root

    stop = false
    place = "#{method} @ #{file}:#{line}"
    if @last_place != place
      if @last_start_at
        took = Time.now - @last_start_at
        if took > 0.1
          PryMoves.messages << "#{@last_place} took #{took} seconds"
          stop = true
        end
      end
      @last_place = place
      @last_start_at = Time.now
    end

    stop
  end

end
