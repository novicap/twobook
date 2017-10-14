RSpec.describe Medici::Handler do
  let(:event) { Accounting::Events::BirthdayMoneyReceived.new(amount: 1000, person_name: 'jackson') }
  let(:handler) { Accounting::Handlers::ProcessIncomingMoney.new(event: event) }

  it 'moves money around as expected' do
    accounts = handler.run([])
    expect(accounts.count).to eq 2

    expect_account_balances accounts, [
      'current_account:jackson', 1000,
      'birthday_money:jackson', 1000,
    ]
  end

  it 'provides a list of account requirements, given an event' do
    requirements = handler.account_requirements
    expect(requirements.count).to eq 3
    expect(requirements.first[:requested]).to eq :one
    expect(requirements.first[:query]).to be_a(Medici::AccountQuery)
  end

  context 'when the handler is given some extra data at initialization' do
    let(:different_handler) do
      Accounting::Handlers::ProcessIncomingMoney.new(event: event, saving_percentage: 0.1)
    end

    it 'handles an event differently' do
      accounts = different_handler.run([])

      expect_account_balances accounts, [
        'current_account:jackson', 900,
        'birthday_money:jackson', 1000,
        'savings:jackson', 100,
      ]
    end
  end
end
