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
      has :amount
    end
  end
end
