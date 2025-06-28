module TraitEngine
  module Registry
    @store = {}

    def self.register(name, &block)
      raise ArgumentError, "block required" unless block
      raise TraitEngine::Error, "Registry frozen" if @store.frozen?

      @store[name.to_sym] = block
    end

    def self.fetch(name)
      @store.fetch(name.to_sym) { raise TraitEngine::UnknownFunctionError, name }
    end

    def self.freeze_registry!
      @store.freeze
    end

    def self.reset_for_reload!
      @store.clear unless @store.frozen?
    end
  end
end
