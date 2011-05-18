module RightSupport
  module Services
    class UnknownService < Exception; end
    class MissingConfiguration < Exception; end

    CLASS_CONFIG_KEY = 'class'

    @services = []
    @registry = {}

    #TODO docs
    def self.register(info)
      info.each_pair { |name, _| @registry[name] = info }
    end

    #TODO docs
    def self.reset

    end

    #TODO docs
    def self.[](name)
      name = name.to_s
      info = @registry[name]
      raise UnknownService, "The #{name} service has not been registered" unless info

      #Clear the cache when ANY ServiceInfo changes. Brutal but simple...
      @services = {} if info.freshen

      service = @services[name]

      unless service
        settings = info[name]
        #TODO account for modules (steal Rails constantize?)
        klass = Object.const_get(settings[CLASS_CONFIG_KEY])
        raise MissingConfiguration, "Every service must have a 'class' setting" unless klass
        service = klass.new(settings)
        @services[name] = service
      end

      return service
    end

    #TODO docs
    def self.method_missing(name)
      self[name]
    end
  end
end

Dir[File.expand_path('../services/*.rb', __FILE__)].each do |filename|
  require filename
end
