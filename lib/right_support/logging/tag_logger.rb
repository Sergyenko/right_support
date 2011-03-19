module RightSupport::Logging
  class TagLogger < FilterLogger
    def filter(severity, message)
      @tls_id ||= "tag_logger_#{self.object_id}"
      tag = Thread.current[@tls_id] || ''
      if tag
        tag + message
      else
        message
      end
    end

    def tag=(tag)
      @tls_id ||= "tag_logger_#{self.object_id}"
      Thread.current[@tls_id] = tag
    end
  end
end