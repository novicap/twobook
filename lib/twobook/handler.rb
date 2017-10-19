require_relative 'handler/query_helpers'
require_relative 'handler/booking_helpers'

module Twobook
  class Handler
    include QueryHelpers
    include BookingHelpers

    attr_reader :event_in_process, :data_in_process

    def initialize(event:, **data)
      raise 'Must be initialized with an event' unless event.is_a?(Event)
      @event_in_process = event
      @data_in_process = {
        **data,
        **event.data,
      }
    end

    def run(accounts)
      raise 'No event set; was this handler initialized properly?' unless @event_in_process.present?
      @accounts_in_process = accounts.map(&:clone)

      Utilities.match_params(
        method(:handle),
        {
          **@data_in_process,
          happened_at: @event_in_process.happened_at,
          event_name: @event_in_process.class.event_name,
        },
        "Cannot run handler #{self.class.handler_name} for event #{@event_in_process}",
      )

      @accounts_in_process
    end

    def handle
      raise 'This handler needs a #handle method'
    end

    def name
      self.class.handler_name
    end

    def self.handler_name
      name.underscore.gsub("#{Twobook.configuration.accounting_namespace.underscore}/handlers/", '')
    end

    def self.from_name(name)
      match = types.detect { |t| t.name =~ /#{name.camelize}$/ }
      raise "Bad handler name: #{name}" unless match
      match
    end

    def self.types
      Utilities.types(self)
    end
  end
end
