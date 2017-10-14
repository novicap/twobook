module Medici
  class Event
    include Comparable

    attr_reader :data, :happened_at, :uuid, :partial_order
    attr_accessor :entries, :agreements

    def initialize(happened_at: Time.current, **data)
      @happened_at = happened_at
      @data = data
      @uuid = SecureRandom.uuid
      @agreements = []
      @entries = []

      remaining_keys_to_match = self.class.has.deep_dup
      @data.each do |k, v|
        raise "Cannot initialize event #{inspect}: unexpected parameter #{k}" if remaining_keys_to_match.delete(k).nil?
        raise "Cannot initialize event #{inspect}: #{k} is nil" if v.nil?

        @data[k] = Medici.wrap_number(v) if v.is_a?(Numeric)

        define_singleton_method k, -> { @data.dig(k) }
      end
      raise "Cannot initialize event #{inspect}: required #{remaining_keys_to_match}" if remaining_keys_to_match.any?
    end

    def clone
      c = super
      c.instance_variable_set(:@entries, @entries.map(&:clone))
      c.instance_variable_set(:@data, @data.deep_dup)
      c
    end

    def fetch_agreements!
      raise "I don't know how to fetch the agreements for #{@name}"
    end

    def fetch_and_assign_agreements!
      @agreements = fetch_agreements!
    end

    def inspect
      "<#{self.class.name} @data=#{@data} @happened_at=#{@happened_at}>"
    end

    def update_partial_order(i)
      @partial_order = i
      self
    end

    def update_happened_at(happened_at)
      @happened_at = happened_at
      self
    end

    def ==(other)
      other.is_a?(Event) && @uuid == other.uuid
    end

    def <=>(other)
      return -1 if other.is_a?(Symbol) && other == :everything
      return @happened_at <=> other if other.is_a?(Time)
      [@happened_at, @partial_order || 0] <=> [other.happened_at, other.partial_order || 0]
    end

    def self.event_name
      name.underscore.gsub("#{Medici.configuration.accounting_namespace.underscore}/events/", '')
    end

    def self.from_name(name)
      match = types.detect { |t| t.name == "#{Medici.configuration.accounting_namespace}::Events::#{name.camelize}" }
      raise "Bad event name #{name}" unless match
      match
    end

    def self.types
      Utilities.types(self)
    end

    def self.has(*args)
      @has ||= []
      return @has if args.empty?
      @has += args
    end
  end
end
