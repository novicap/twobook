module Twobook
  module Corrections
    def self.make_deletion(event, accounts, history, happened_at: Time.current)
      correct_history = history - [event]

      snapshots = accounts.map do |a|
        Serialization.serialize_account(a, before_event: event, allow_empty: false)
      end.compact

      CorrectionMade.new(
        account_snapshots: snapshots,
        corrected_events: correct_history.map { |e| Serialization.serialize_event(e) },
        correction_explanation: { event_uuid: event.uuid, type: 'deletion' },
        happened_at: happened_at,
      )
    end

    def self.make_edit(edited_event, accounts, history, happened_at: Time.current)
      index = history.index(edited_event)
      correct_history = history.deep_dup
      correct_history[index] = edited_event

      snapshots = accounts.map do |a|
        Serialization.serialize_account(a, before_event: edited_event, allow_empty: false)
      end.compact

      CorrectionMade.new(
        account_snapshots: snapshots,
        corrected_events: correct_history.map { |e| Serialization.serialize_event(e) },
        correction_explanation: { event_uuid: edited_event.uuid, type: 'edit', new_parameters: edited_event.data },
        happened_at: happened_at,
      )
    end

    class CorrectionBuffer < Twobook::Account
      account_type :assets
    end

    class CorrectionMade < Twobook::Event
      has :account_snapshots, :corrected_events, :correction_explanation

      def fetch_agreements!
        [Correction.new]
      end
    end

    class SimulatedDifferenceAdjustment < Handler
      def handle(account_snapshots:, corrected_events:)
        correct_accounts = self.class.simulate_correction(corrected_events, account_snapshots)

        correct_accounts.each do |correct|
          original = where(name: correct.name).execute(@accounts_in_process).first
          adjust_original_account_balance(original, correct)
          adjust_original_account_data(original, correct)
        end
      end

      def adjust_original_account_balance(original, correct)
        correct_balance = correct.balance || Twobook.wrap_number(0)
        original_balance = original.balance || Twobook.wrap_number(0)
        diff = correct_balance - original_balance
        return if diff.zero?

        if original.class.account_type == :records
          record original, amount: diff
        else
          diff *= -1 if %i(revenue liabilities).include?(original.class.account_type)
          book diff, cr: buffer_account, dr: original if diff.positive?
          book (-1 * diff), cr: original, dr: buffer_account if diff.negative?
        end
      end

      def adjust_original_account_data(original, correct)
        diff = correct.data.to_a - original.data.to_a
        return if diff.empty?
        original << entry(0, data: diff.to_h)
      end

      def accounts(corrected_events:, account_snapshots:)
        corrected_accounts = self.class.simulate_correction(corrected_events, account_snapshots)

        requirements = corrected_accounts.map do |account|
          query = AccountQuery.where(
            category: account.class.category,
            **account.data.slice(*account.class.name_includes),
          )
          existing(query)
        end

        labelled_requirements = (0...requirements.count).map do |n|
          "requirement_#{n}_account".to_sym
        end.zip(requirements).to_h

        {
          buffer_account: one(where(category: 'twobook/corrections/correction_buffer')),
          **labelled_requirements,
        }
      end

      def self.simulate_correction(events, accounts)
        deserialized_events = events.map { |e| Serialization.deserialize_event(e) }
        deserialized_accounts = accounts.map { |a| Serialization.deserialize_account(a) }
        Twobook.simulate(deserialized_events, deserialized_accounts)
      end
    end

    class Correction < Agreement
      handles 'twobook/corrections/correction_made', with: 'twobook/corrections/simulated_difference_adjustment'
    end
  end
end
