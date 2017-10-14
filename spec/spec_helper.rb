require 'bundler/setup'
require 'medici'
require_relative 'medici/test_accounting_classes'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def expect_account_balances(accounts, table)
  table.each_slice(2) do |name_or_category, total_balance|
    query, reason = (
      if name_or_category =~ /:/
        [
          Medici::AccountQuery.where(name: name_or_category),
          "expected balance of account \"#{name_or_category}\" to be #{total_balance}, got %s",
        ]
      else
        [
          Medici::AccountQuery.where(category: name_or_category),
          "expected sum of accounts in category \"#{name_or_category}\" to be #{total_balance}, got %s",
        ]
      end
    )

    balance = query.execute(accounts).map(&:balance).sum
    expect(balance).to be_within(0.01).of(total_balance), format(reason, balance)
  end
end
