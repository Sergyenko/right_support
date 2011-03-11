require 'syslog'
require 'logger'

module RightSupport
  class SystemLogger < Logger
    LOGGER_LEVELS = {
      UNKNOWN => :alert,
      FATAL   => :err,
      ERROR   => :warning,
      WARN    => :notice,
      INFO    => :info,
      DEBUG   => :debug
    }

    SYSLOG_LEVELS = LOGGER_LEVELS.invert
    DEFAULT_SYSLOG_LEVEL = :alert

    @@syslog = nil

    def initialize(program_name='ruby')
      @level = Logger::DEBUG
      @@syslog ||= Syslog.open(program_name)
    end

    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN
      if @@syslog.nil? or severity < @level
        return true
      end

      progname ||= @progname

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end

      return emit_syslog(severity, message)
    end

    def <<(msg)
      info(msg)
    end

    def close
      return true
    end

    private

    def emit_syslog(severity, message)
      level = SYSLOG_LEVELS[severity] || DEFAULT_SYSLOG_LEVEL
      parts = clean(message)
      parts.each { |part| @@syslog.send(level, part) }
      return true
    end

    def clean(message)
      message = message.to_s.dup
      message.strip!
      message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
      message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
      return message.split(/[\n\r]+/)
    end

  end
end
