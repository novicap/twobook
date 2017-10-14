module Medici
  class Entry
    attr_reader :amount, :event, :transaction_id, :account, :data

    def initialize(amount, event, transaction_id: nil, data: {})
      @amount = Medici.wrap_number(amount)
      @event = event
      @transaction_id = transaction_id
      @data = data
    end
  end
end
