module Twobook
  module Serialization
    def self.serialize_event(event)
      {
        name: event.class.event_name,
        data: event.data,
        agreements: event.agreements.map { |a| serialize_agreement(a) },
      }.as_json
    end

    def self.deserialize_event(serialized)
      serialized.deep_symbolize_keys!

      klass = Event.from_name(serialized[:name])
      event = klass.new(
        **deserialize_data(serialized[:data]),
      )

      event.agreements = serialized[:agreements].map { |a| deserialize_agreement(a) }
      event
    end

    def self.serialize_agreement(agreement)
      {
        name: agreement.class.agreement_name,
        data: agreement.data,
      }.as_json
    end

    def self.deserialize_agreement(serialized)
      serialized.deep_symbolize_keys!
      klass = Agreement.from_name(serialized[:name])
      klass.new(**deserialize_data(serialized[:data]))
    end

    def self.serialize_account(account, before_event: nil, allow_empty: true)
      balance, data = if before_event.nil?
                        [account.balance, account.data]
                      else
                        [
                          account.balance_before_event(before_event),
                          account.data_before_event(before_event),
                        ]
                      end

      # If we don't allow empty accounts...
      unless allow_empty
        only_has_name_data = data.keys.all? { |key| key.in?(account.class.name_includes) }
        return nil if balance.zero? && only_has_name_data
      end

      {
        name: account.name,
        balance: balance,
        data: data,
      }.as_json
    end

    def self.deserialize_account(serialized)
      serialized.deep_symbolize_keys!
      klass = Account.from_name(serialized[:name])
      immutable_data = deserialize_data(serialized[:data].slice(*klass.name_includes))
      mutable_data = deserialize_data(serialized[:data].slice(*klass.has))
      account = klass.new(balance: serialized[:balance], **immutable_data)
      account.update_mutable_data(mutable_data)
      account
    end

    def self.deserialize_data(data)
      converted = data.deep_symbolize_keys
      converted.each { |k, v| converted[k] = try_parse_date(v) if k.to_s.end_with?("_at") }
      converted
    end

    def self.try_parse_date(string)
      return string if string.is_a?(Time)
      Time.zone.parse(string)
    rescue => _
      raise "Could not convert _at data on account #{inspect}"
    end
  end
end
