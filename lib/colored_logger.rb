require 'logger'

class ColoredLogger
  COLORS = {
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    gray: 37
  }

  def self.create(name)
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    color = COLORS.values.sample
    node_color = "\e[#{color}m"
    reset_color = "\e[0m"

    logger.formatter = proc do |severity, datetime, progname, msg|
      severity_color = case severity
        when "DEBUG" then "\e[#{COLORS[:gray]}m"
        when "INFO"  then "\e[#{COLORS[:green]}m"
        when "WARN"  then "\e[#{COLORS[:yellow]}m"
        when "ERROR" then "\e[#{COLORS[:red]}m"
        else "\e[#{COLORS[:gray]}m"
      end
      
      "[#{datetime}] #{severity_color}#{severity}#{reset_color} #{node_color}#{name}#{reset_color} -- #{msg}\n"
    end

    logger
  end
end
