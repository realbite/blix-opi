# frozen_string_literal: true

unless Hash.method_defined? :transform_keys
  class Hash
    # Returns a new hash with all keys converted using the block operation.
    #
    #  hash = { name: 'Rob', age: '28' }
    #
    #  hash.transform_keys{ |key| key.to_s.upcase }
    #  # => {"NAME"=>"Rob", "AGE"=>"28"}
    def transform_keys
      result = {}
      each_key do |key|
        result[yield(key)] = self[key]
      end
      result
    end
  end
end

module OPI
  # indifferent hash for symbols or string keys.
  # stores keys as a string

  class StringHash < Hash

    alias_method :parent_merge!, :merge!

    # initialize without conversion. params must be in
    # string key format.
    def initialize(*params)
      super()
      parent_merge!(*params) unless params.empty?
    end

    # create with conversion
    def self.create(params)
      h = new
      h.merge(params)
      h
    end

    def [](k)
      super(k.to_s)
    end

    def get(k, default = nil)
      if key?(k.to_s)
        self[k]
      else
        default
      end
    end

    def merge(*params)
      super(* params.map { |h| h.transform_keys(&:to_s) })
    end

    def merge!(*params)
      super(* params.map { |h| h.transform_keys(&:to_s) })
    end

    def replace(h)
      super(h.transform_keys(&:to_s))
    end

    def has_key?(key)
      super(key.to_s)
    end

    def member?(key)
      super(key.to_s)
    end

    def store(key, value)
      super(key.to_s, value)
    end

    def key(key)
      super(key.to_s)
    end

    def key?(key)
      super(key.to_s)
    end

    def []=(k, v)
      super(k.to_s, v)
    end

    def include?(k)
      super(k.to_s)
    end

    def delete(k)
      super(k.to_s)
    end

  end
end
