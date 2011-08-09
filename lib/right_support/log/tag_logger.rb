#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'logger'

module RightSupport::Log
  # A logger that prepends a tag to every message that is emitted. Can be used to
  # correlate logs with a Web session ID, transaction ID or other context.
  #
  # The user of this logger is responsible for calling #tag= to set the tag as
  # appropriate, e.g. in a Web request around-filter.
  #
  # This logger uses thread-local storage (TLS) to provide tagging on a per-thread
  # basis; however, it does not account for EventMachine, neverblock, the use of
  # Ruby fibers, or any other phenomenon that can "hijack" a thread's call stack.
  #
  class TagLogger < FilterLogger
    # Prepend the current tag to the log message; return the same severity and
    # the modified message.
    #
    # === Parameters
    # severity(Integer):: one of the severity constants defined by Logger
    # messgae(String):: the log message
    #
    # === Return
    # Returns a pair consisting of the filtered [severity, message].
    #
    def filter(severity, message)
      @tls_id ||= "tag_logger_#{self.object_id}"
      tag = Thread.current[@tls_id] || ''
      if tag
        return [severity, tag + message]
      else
        return [severity, message]
      end
    end

    attr_reader :tag
    
    # Set the tag for this logger.
    #
    # === Parameters
    # tag(String|nil):: the new tag, or nil to remove the tag
    #
    # === Return
    # String:: returns the new tag
    def tag=(tag)
      @tag = tag
      @tls_id ||= "tag_logger_#{self.object_id}"
      Thread.current[@tls_id] = @tag
    end
  end
end