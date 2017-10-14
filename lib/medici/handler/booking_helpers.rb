module Medici
  class Handler
    # Mixin for Handler with some booking shorthand.
    # Expects @account_in_process and @event_in_process to be set.
    module BookingHelpers
      def entry(amount, transaction_id: nil, data: {})
        raise 'Cannot create entry - not currently processing an event' if @event_in_process.blank?
        new_entry = Entry.new(amount, @event_in_process, transaction_id: transaction_id, data: data)
        @event_in_process.entries << new_entry
        new_entry
      end

      def record(account, amount: 0, **data)
        account << entry(amount, data: data)
      end

      def book(amount, debit: nil, credit: nil)
        to_debit = debit
        to_credit = credit
        raise 'Must credit one account and debit one account' unless to_debit && to_credit
        transaction_id = SecureRandom.uuid
        debit amount, to_debit, transaction_id: transaction_id
        credit amount, to_credit, transaction_id: transaction_id
      end

      def debit(amount, account, **opts)
        case account.class.account_type
        when :assets
          account << entry(amount, **opts)
        when :liabilities
          account << entry(-amount, **opts)
        when :revenue
          account << entry(-amount, **opts)
        when :expenses
          account << entry(amount, **opts)
        else
          raise "Invalid account type #{account.account_type}"
        end
      end

      def credit(amount, account, **opts)
        case account.class.account_type
        when :assets
          account << entry(-amount, **opts)
        when :liabilities
          account << entry(amount, **opts)
        when :revenue
          account << entry(amount, **opts)
        when :expenses
          account << entry(-amount, **opts)
        else
          raise "Invalid account type #{account.account_type}"
        end
      end

      def add_account(account)
        raise 'Cannot add accounts: not currently processing accounts' if @accounts_in_process.nil?
        if @accounts_in_process.include?(account)
          raise "Cannot add account #{account.name}: was already processing one with the same name."
        end

        @accounts_in_process << account
        account
      end
    end
  end
end
