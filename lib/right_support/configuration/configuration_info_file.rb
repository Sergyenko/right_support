module RightSupport::Configuration
  
  class ConfigurationInfoFile
    
    class UnknownKey < Exception; end

    def initialize(filename, environment, &freshen_callback)
      @filename         = filename
      @environment      = environment.to_s
      @freshen_callback = freshen_callback

      # populate data
      freshen
    end

    # add not about callback needing to use quotes not symbols since we are dealing with raw yaml data
    def freshen
      mtime       = File.stat(@filename).mtime
      last_mtime  = @last_mtime
      @last_mtime = mtime
      
      # file does not need to be freshened as an update was not deteced
      return false if last_mtime && mtime <= last_mtime
      
      content = File.read(@filename)
      @config = YAML.load(content)
      
      # invoke callback if one is provided
      @freshen_callback.call(@config[@environment]) if @freshen_callback
      
      return true
    end
    
    def [](key)
      key = key.to_s
      
      # freshen the configuration
      freshen
      
      if @config.has_key?(@environment) && @config[@environment].has_key?(key)
        value = @config[@environment][key]
      else
        value = @config["common"] && @config["common"][key]
      end
      
      return value if value
      
      raise UnknownKey, "Value was not found for #{key}"
    end
    
  end
  
end
