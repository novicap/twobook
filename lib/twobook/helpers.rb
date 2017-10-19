module Twobook
  def self.where(**conditions)
    AccountQuery.where(**conditions)
  end

  module Helpers
    def expect_account_balances(accounts, table)
      table.each_slice(2) do |name_or_category, total_balance|
        query, reason = (
          if name_or_category =~ /:/
            [
              Twobook::AccountQuery.where(name: name_or_category),
              "expected balance of account \"#{name_or_category}\" to be #{total_balance}, got %s",
            ]
          else
            [
              Twobook::AccountQuery.where(category: name_or_category),
              "expected sum of accounts in category \"#{name_or_category}\" to be #{total_balance}, got %s",
            ]
          end
        )

        balance = query.on(accounts).map(&:balance).sum
        expect(balance).to be_within(0.01).of(total_balance), format(reason, balance)
      end
    end
  end
end
