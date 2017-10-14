RSpec.describe Medici::Agreement do
  let(:agreement) { Accounting::Agreements::SavingsScheme.new(saving_percentage: 0.1) }
  let(:event) { Accounting::Events::BirthdayMoneyReceived.new(amount: 100, person_name: 'jackson') }

  it 'can have data' do
    expect(agreement.saving_percentage).to eq 0.1
  end

  it 'has recorded its handlers' do
    expect(agreement.class.handles).to eq('birthday_money_received' => ['process_incoming_money'])
  end

  it 'provides a correctly initialized handler for an event' do
    handlers = agreement.handlers_for(event)
    expect(handlers.first).to be_a(Accounting::Handlers::ProcessIncomingMoney)
    expect(handlers.first.data_in_process).to eq(
      saving_percentage: 0.1,
      amount: 100,
      person_name: 'jackson',
    )
  end
end
