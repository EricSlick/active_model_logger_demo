module HomeHelper
  def log_level_class(level)
    case level.to_s.downcase
    when "error"
      "danger"
    when "warn", "warning"
      "warning"
    when "info"
      "info"
    when "debug"
      "secondary"
    else
      "light"
    end
  end
end
