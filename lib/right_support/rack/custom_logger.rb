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

module RightSupport::Rack
  # A Rack middleware that allows an arbitrary object to be used as the Rack logger.
  # This is more flexible than Rack's built-in Logger middleware, which always logs
  # to a file-based Logger and doesn't allow you to control anything other than the
  # filename.
  class CustomLogger
    # Initialize an instance of the middleware.
    #
    # === Parameters
    # app(Object):: the inner application or middleware layer; must respond to #call
    # level(Integer):: one of the Logger constants: DEBUG, INFO, WARN, ERROR, FATAL
    # logger(Logger):: (optional) the Logger object to use, if other than default
    #
    def initialize(app, level = ::Logger::INFO, logger = nil)
      @app, @level = app, level

      logger ||= ::Logger.new(env['rack.errors'])
      logger.level = @level
      @logger = logger
    end

    # Add a logger to the Rack environment and call the next middleware.
    #
    # === Parameters
    # env(Hash):: the Rack environment
    #
    # === Return
    # always returns whatever value is returned by the next layer of middleware
    def call(env)
      env['rack.logger'] = @logger
      return @app.call(env)
    end
  end
end
