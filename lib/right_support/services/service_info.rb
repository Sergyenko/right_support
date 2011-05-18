module RightSupport::Services
  class ServiceInfo
    def self.from_file(filename)
      ServiceInfoFile.new(filename)
    end

    #TODO docs
    def initialize(services={})
      @services = services
    end

    #TODO docs
    def each_pair
      @services.each_pair { |name, settings| yield(name, settings) }
    end

    #TODO docs
    def [](key)
      @services[key]
    end

    #TODO docs
    def freshen
      false
    end
  end
end