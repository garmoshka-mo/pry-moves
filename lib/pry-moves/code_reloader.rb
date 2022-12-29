class CodeReloader

  def initialize
    @timestamps = {}
    traverse_files do |path|
      @timestamps[path] = File.mtime(path)
    end
  end

  def reload
    traverse_files do |path|
      if @timestamps[path] != File.mtime(path)
        @timestamps[path] = File.mtime(path)
        reload_file path
        # Log.info "⚡️ file reloaded #{path}"
      end
    end
  end

  private

  def reload_file path
    hide_from_stack = true
    load path
  rescue SyntaxError => e
    PryMoves.debug_error ["🛠  Syntax error:".red, e.message].join "\n"
  end

  def traverse_files
    paths = PryMoves.reload_ruby_scripts[:monitor]
    except = PryMoves.reload_ruby_scripts[:except]
    paths.each do |root|
      files = Dir.glob("#{root}/**/*")
      files.each do |path|
        if path.end_with? '.rb' and
            not except.any? {|_| path.start_with? _}
          yield path
        end
      end
    end
  end

end