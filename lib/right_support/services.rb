module RightSupport
  module Services
    class UnknownService < Exception; end
    class MissingConfiguration < Exception; end

    CLASS_CONFIG_KEY    = 'class'
    SETTINGS_CONFIG_KEY = 'settings'

    #Map of service_name => service_object
    @services = {}
    #Map of service_name => service_info [who defines that service]
    @service_infos = {}

    #TODO docs
    def self.register(info)
      info.each_pair { |name, _| @service_infos[name] = info }
    end

    #TODO docs
    def self.reset
      @services = {}
      @service_infos = {}
    end

    #TODO docs
    def self.method_missing(name)
      name = name.to_s
      info = @service_infos[name]
      raise UnknownService, "The #{name} service has not been registered" unless info

      #Clear the cache when ANY ServiceInfo changes. Brutal but simple...
      @services = {} if info.freshen

      service = @services[name]

      #Instantiate the service proxy object if needed
      unless service
        service_stanza = info[name]
        #TODO account for modules (steal Rails constantize?)
        klass = RightSupport::Inflection.constantize(service_stanza[CLASS_CONFIG_KEY])
        raise MissingConfiguration, "Every service must have a 'class' setting" unless klass
        service = klass.new(service_stanza[SETTINGS_CONFIG_KEY])
        @services[name] = service
      end

      return service
    end
  end
end

Dir[File.expand_path('../services/*.rb', __FILE__)].each do |filename|
  require filename
end
