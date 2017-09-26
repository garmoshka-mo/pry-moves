class << Pry

  alias start_without_pry_nav_orig start_without_pry_nav

  def start_without_pry_nav(target = TOPLEVEL_BINDING, options = {})
    PryDebugger.intercept target, options
    start_without_pry_nav_orig target, options
  end

end