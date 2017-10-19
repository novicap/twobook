module Twobook
  class Entry
    attr_reader :amount, :event, :transaction_id, :account, :data

    def initialize(amount, event, transaction_id: nil, data: {})
      @amount = Twobook.wrap_number(amount)

      raise 'Required an Event' unless event.is_a?(Event)
      @event = event

      @transaction_id = transaction_id
      @data = data
    end
  end
end
