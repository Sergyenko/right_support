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
  if_require_succeeds('syslog') do
    # A logger that forwards log entries to the Unix syslog facility, but complies
    # with the interface of the Ruby Logger object and faithfully translates log
    # severities and other concepts. Provides optional cleanup/filtering in order
    # to keep the syslog from having weird characters or being susceptible to log
    # forgery.
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

      # Initialize this process's syslog facilities and construct a new syslog
      # logger object.
      #
      # === Parameters
      # program_name(String):: the syslog program name, 'ruby' by default
      # options(Hash):: (optional) configuration options to use, see below
      #
      # === Options
      # :facility:: the syslog facility to use for messages, 'local0' by default
      # :split(true|false):: if true, splits multi-line messages into separate syslog entries
      # :color(true|false):: if true, passes ANSI escape sequences through to syslog
      #
      def initialize(program_name='ruby', options={})
        @options = DEFAULT_OPTIONS.merge(options)
        @level = Logger::DEBUG

        facility = options[:facility] || 'local0'
        fac_map = {'user'=>8}
        (0..7).each { |i| fac_map['local'+i.to_s] = 128+8*i }
        @@syslog ||= Syslog.open(program_name, nil, fac_map[facility.to_s])
      end

      # Log a message if the given severity is high enough.  This is the generic
      # logging method.  Users will be more inclined to use #debug, #info, #warn,
      # #error, and #fatal.
      #
      # === Parameters
      # severity(Integer):: one of the severity constants defined by Logger
      # message(Object):: the message to be logged
      # progname(String):: ignored, the program name is fixed at initialization
      #
      # === Block
      # If message is nil and a block is supplied, this method will yield to
      # obtain the log message.
      #
      # === Return
      # true:: always returns true
      #
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

      # Emit a log entry at INFO severity.
      #
      # === Parameters
      # msg(Object):: the message to log
      #
      # === Return
      # true:: always returns true
      #
      def <<(msg)
        info(msg)
      end

      # Do nothing. This method is provided for Logger interface compatibility.
      #
      # === Return
      # true:: always returns true
      #
      def close
        return true
      end

      private

      # Call the syslog function to emit a syslog entry.
      #
      # === Parameters
      # severity(Integer):: one of the Logger severity constants
      # message(String):: the log message
      #
      # === Return
      # true:: always returns true
      def emit_syslog(severity, message)
        level = SYSLOG_LEVELS[severity] || DEFAULT_SYSLOG_LEVEL
        @@syslog.send(level, message)
        return true
      end

      # Perform cleanup, output escaping and splitting on message.
      # The operations that it performs can vary, depending on the
      # options that were passed to this logger at initialization
      # time.
      #
      # === Parameters
      # message(String):: raw log message
      #
      # === Return
      # log_lines([String]):: an array of String messages that should be logged separately to syslog
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
end
