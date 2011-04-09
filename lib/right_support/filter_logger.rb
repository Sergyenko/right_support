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

module RightSupport
  # A logger than encapsulates an underlying Logger object and filters log entries
  # before they are passed to the underlying Logger. Can be used to for various log-
  # processing tasks such as filtering sensitive data or tagging log lines with a
  # context marker.
  class FilterLogger < Logger
    # Initialize a new instance of this class.
    #
    # === Parameters
    # actual_logger(Logger):: The actual, underlying Logger object
    #
    def initialize(actual_logger)
      @actual_logger = actual_logger

    end

    # Add a log line, filtering the severity and message before calling through
    # to the underlying logger's #add method.
    #
    # === Parameters
    # severity(Integer):: one of the Logger severity constants
    # message(String):: the message to log, or nil
    # progname(String):: the program name, or nil
    #
    # === Block
    # If message == nil and a block is given, yields to the block in order to
    # capture the log message. This matches the behavior of Logger, but ensures
    # the severity and message are still filtered.
    #
    # === Return
    # the result of the underlying logger's #add
    def add(severity, message = nil, progname = nil, &block)
      severity ||= UNKNOWN
      return true if severity < level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
        end
      end

      severity, message = filter(severity, message)
      return @actual_logger.add(severity, message) if message
    end

    # Proxies to the encapsulated Logger object. See Logger#<< for info.
    def <<(msg)
      @actual_logger << msg
    end

    # Proxies to the encapsulated Logger object. See Logger#close for info.
    def close
      @actual_logger.close
    end

    # Proxies to the encapsulated Logger object. See Logger#level for info.
    def level
      @actual_logger.level
    end

    # Proxies to the encapsulated Logger object. See Logger#level= for info.
    def level=(new_level)
      @actual_logger.level = new_level
    end

    # Proxies to the encapsulated Logger object. See Logger#debug? for info.
    def debug?; @actual_logger.debug?; end

    # Proxies to the encapsulated Logger object. See Logger#info? for info.
    def info?; @actual_logger.info?; end

    # Proxies to the encapsulated Logger object. See Logger#warn? for info.
    def warn?; @actual_logger.warn?; end

    # Proxies to the encapsulated Logger object. See Logger#error? for info.
    def error?; @actual_logger.error?; end

    # Proxies to the encapsulated Logger object. See Logger#fatal? for info.
    def fatal?; @actual_logger.fatal?; end

    protected

    # Filter a log line, transforming its severity and/or message before it is
    # passed to the underlying logger.
    #
    # === Parameters
    # severity(Integer):: one of the severity constants defined by Logger
    # messgae(String):: the log message
    #
    # === Return
    # Returns a pair consisting of the filtered [severity, message].
    def filter(severity, message)
      return [severity, message]
    end
  end
end