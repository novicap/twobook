RSpec.describe 'Medici.simulate' do
  let(:agreement) { Accounting::Agreements::SavingsScheme.new(saving_percentage: 0.1) }
  let(:event) do
    event = Accounting::Events::BirthdayMoneyReceived.new(amount: 1000, person_name: 'jackson')
    event.agreements = [agreement]
    event
  end

  it 'simulates a simple event' do
    accounts = Medici.simulate(event, [])
    expect_account_balances accounts, [
      'current_account:jackson', 900,
      'birthday_money:jackson', 1000,
      'savings:jackson', 100,
    ]
  end

  it 'simulates a chain of events' do
    accounts = Medici.simulate([event, event], [])
    expect_account_balances accounts, [
      'current_account:jackson', 1800,
      'birthday_money:jackson', 2000,
      'savings:jackson', 200,
    ]
  end
end
