module Medici
  class Agreement
    attr_reader :data

    def initialize(data = {})
      @data = data

      remaining_keys_to_match = self.class.has.deep_dup
      @data.each do |k, v|
        raise "Cannot initialize agreement #{inspect}: unexpected parameter #{k}" if remaining_keys_to_match.delete(k).nil?
        raise "Cannot initialize agreement #{inspect}: #{k} is nil" if v.nil?
        define_singleton_method k, -> { @data.dig(k) }

        @data[k] = Medici.wrap_number(v) if v.is_a?(Numeric)
      end
      raise "Cannot initialize agreement #{inspect}: required #{remaining_keys_to_match}" if remaining_keys_to_match.any?
    end

    def handlers_for(event)
      handler_names = self.class.handles[event.class.event_name]

      if handler_names.nil? || handler_names.none?
        raise "Missing handler: #{inspect} cannot handle #{event.class.event_name}"
      end

      handler_names.map do |handler_name|
        Handler.from_name(handler_name).new(
          event: event,
          **@data,
        )
      end
    end

    def inspect
      "<#{self.class.name} @data=#{@data}>"
    end

    def self.agreement_name
      name.underscore.gsub("#{Medici.configuration.accounting_namespace.underscore}/agreements/", '')
    end

    def self.handles(event_name = nil, with: nil)
      @handles ||= {}
      return @handles if event_name.nil?

      if @handles[event_name].present?
        raise "Duplicate handler: more than one handler defined for #{event_name} on #{name}"
      end

      # Check that all names map to valid classes
      Event.from_name(event_name)
      handler_names = with.is_a?(Array) ? with : [with]
      handler_names.each { |handler_name| Handler.from_name(handler_name) }

      @handles[event_name] = handler_names
    end

    def self.has(*args)
      @has ||= []
      return @has if args.empty?
      @has += args
    end

    def self.from_name(name)
      match = types.detect do |t|
        t.name == "#{Medici.configuration.accounting_namespace}::Agreements::#{name.camelize}"
      end
      raise "Bad agreement name in database: #{name}" unless match
      match
    end

    def self.types
      Utilities.types(self)
    end
  end
end
