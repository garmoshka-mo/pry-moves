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
        if reload_file path
          @timestamps[path] = File.mtime(path)
          # Log.info "⚡️ file reloaded #{path}"
        end
      end
    end
  end

  private

  def reload_file path
    hide_from_stack = true
    load path
    true
  rescue SyntaxError => e
    PryMoves.debug_error ["🛠  Syntax error:".red, e.message].join "\n"
    false
  end

  def traverse_files
    paths = PryMoves.reload_ruby_scripts[:monitor]
    except = PryMoves.reload_ruby_scripts[:except] + rails_path_exceptions
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

  def rails_path_exceptions
    if defined?(Rails)
      Rails.autoloaders.main.ignore.map do
        _1.to_s.gsub /^#{Rails.root.to_s}\//, ""
      end
    else
      []
    end
  rescue
    []
  end

end
