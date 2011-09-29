module RightSupport::DB
  class CassandraModel
    DEFAULT_TIMEOUT = 10
    class << self
      @@logger=nil
      @@conn = nil
      
      attr_accessor :column_family
      attr_writer :keyspace

      def config
        @@config
      end
      
      def config=(value)
        @@config = value
      end
      
      def logger=(l)
        @@logger=l
      end
      
      def logger
        @@logger 
      end
    
      def keyspace
        @keyspace + "_" + (ENV['RACK_ENV'] || 'development')
      end

      def conn
        return @@conn if @@conn

        config = @@config[ENV["RACK_ENV"]]
        @@conn = Cassandra.new(keyspace, config["server"],{:timeout => RightSupport::DB::CassandraModel::DEFAULT_TIMEOUT})
        @@conn.disable_node_auto_discovery!
        @@conn
      end

      def all(k,opt={})
        list = real_get(k,opt)  
      end
      
      def get(key)
        if (hash = real_get(key)).empty?
          nil
        else
          new(key, hash)
        end
      end

      def real_get(k,opt={})
        if k.is_a?(Array)
          do_op(:multi_get, column_family, k, opt)
        else      
          do_op(:get, column_family, k, opt)
        end
      end

      def insert(key, values,opt={})
        do_op(:insert, column_family, key, values,opt)
      end

      def remove(*args)
        do_op(:remove, column_family, *args)
      end

      def batch(*args,&block)
        raise "Block required!" unless block_given?
        do_op(:batch,*args, &block)
      end
      
      def do_op(meth, *args, &block)
        conn.send(meth, *args, &block)
      rescue IOError
        reconnect
        retry
      end

      def reconnect
        config = @@config[ENV["RACK_ENV"]]
        @@conn = Cassandra.new(keyspace, config["server"],{:timeout => RightSupport::CassandraModel::DEFAULT_TIMEOUT})
        @@conn.disable_node_auto_discovery!
      end

      def ring
        conn.ring
      end
    end

    attr_accessor :key, :attributes

    def initialize(key, attrs={})
      self.key = key
      self.attributes = attrs
    end

    def save
      self.class.insert(key, attributes)
      true
    end
    
    def reload
      self.class.get(key)
    end

    def reload!
      self.attributes = self.class.real_get(key)
      self
    end

    def [](key)
      ret = attributes[key]
      return ret if ret
      if key.kind_of? Integer
        return attributes[Cassandra::Long.new(key)]
      end
    end

    def []=(key, value)
      attributes[key] = value
    end

    def destroy
      self.class.remove(key)
    end

  end
end
