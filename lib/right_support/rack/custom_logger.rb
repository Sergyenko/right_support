require 'logger'

module RightSupport
  module Rack
    # Sets up rack.logger to write to rack.errors stream
    class CustomLogger
      def initialize(app, level = ::Logger::INFO, logger = nil)
        @app, @level = app, level

        logger ||= ::Logger.new(env['rack.errors'])
        logger.level = @level
        @logger = logger
      end

      def call(env)
        env['rack.logger'] = @logger
        @app.call(env)
      ensure
        @logger.close
      end
    end
  end
end
