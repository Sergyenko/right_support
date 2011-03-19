module RightSupport::Logging
  class FilterLogger < Logger
    def initialize(actual_logger)
      @actual_logger = actual_logger
    end

    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN
      return true if severity < @level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
        end
      end

      message = filter(severity, message)
      return @actual_logger.add(severity, message) if message
    end

    def <<(msg)
      @actual_logger << msg
    end

    def close
      @actual_logger.close
    end

    def filter(severity, message)
      message
    end
  end
end