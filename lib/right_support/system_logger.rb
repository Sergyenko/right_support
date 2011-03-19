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

    DEFAULT_OPTIONS = {:split=>false, :color=>false}

    @@syslog = nil

    def initialize(program_name='ruby', options={})
      @options = DEFAULT_OPTIONS.merge(options)
      @level = Logger::DEBUG

      facility = options[:facility] || 'local0'
      fac_map = {'user'=>8}
      (0..7).each { |i| fac_map['local'+i.to_s] = 128+8*i }
      @@syslog ||= Syslog.open(program_name, nil, fac_map[facility.to_s])
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

      parts = clean(message)
      parts.each { |part| emit_syslog(severity, part) }
      return true
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
      @@syslog.send(level, message)
      return true
    end

    def clean(message)
      message = message.to_s.dup
      message.strip!
      message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)

      unless @options[:color]
        message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
      end

      if @options[:split]
        bits = message.split(/[\n\r]+/)
      else
        bits = [message]
      end

      return bits
    end

  end
end
