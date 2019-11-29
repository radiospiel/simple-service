class Simple::Service::Action
  # The IndieHash class defines as much of the Hash interface as necessary for simple-service
  # to successfully run.
  class IndieHash
    def initialize(hsh)
      @hsh = hsh.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
    end

    def keys
      @hsh.keys
    end

    def fetch_values(*keys)
      keys = keys.map(&:to_s)
      @hsh.fetch_values(*keys)
    end

    def key?(sym)
      @hsh.key?(sym.to_s)
    end

    def [](sym)
      @hsh[sym.to_s]
    end

    def merge(other_hsh)
      @hsh = @hsh.merge(other_hsh.send(:__hsh__))
      self
    end

    private

    def __hsh__
      @hsh
    end
  end
end
