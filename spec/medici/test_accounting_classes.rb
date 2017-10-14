module Accounting
  module Accounts
    class CreditCard < Medici::Account
      account_type :liabilities
      name_includes :person_name
      has :expires_at
    end

    class CurrentAccount < Medici::Account
      account_type :assets
      name_includes :person_name
    end

    class Savings < Medici::Account
      account_type :assets
      name_includes :person_name
    end

    class InterestFromCreditCard < Medici::Account
      account_type :expenses
      name_includes :person_name
    end

    class BirthdayMoney < Medici::Account
      account_type :revenue
      name_includes :person_name
    end
  end

  module Events
    class BirthdayMoneyReceived < Medici::Event
      has :amount, :person_name

      def fetch_agreements!
        case person_name
        when 'jackson'
          SavingsScheme.new(savings_percentage: 0)
        when 'medusa'
          SavingsScheme.new(savings_percentage: 0.1)
        end
      end
    end
  end

  module Handlers
    class ProcessIncomingMoney < Medici::Handler
      def handle(amount:, saving_percentage: 0)
        saving = amount * saving_percentage
        book amount - saving, debit: current_account, credit: revenue_account
        book saving, debit: savings_account, credit: revenue_account if saving.positive?
      end

      def accounts(person_name:)
        {
          current_account: one(where(category: 'current_account', person_name: person_name)),
          revenue_account: one(where(category: 'birthday_money', person_name: person_name)),
          savings_account: one(where(category: 'savings', person_name: person_name)),
        }
      end
    end
  end

  module Agreements
    class SavingsScheme < Medici::Agreement
      has :saving_percentage

      handles 'birthday_money_received', with: 'process_incoming_money'
    end
  end
end
