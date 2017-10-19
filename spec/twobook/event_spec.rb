RSpec.describe Twobook::Event do
  it 'initializes' do
    event = described_class.new
    expect(event.uuid).to be_present
    expect(event.happened_at).to be_present
    expect(event.class.event_name).to eq 'twobook/event'
  end

  it 'can have data' do
    event = Accounting::Events::BirthdayMoneyReceived.new(amount: 100, person_name: 'jackson')
    expect(event.amount).to eq 100
  end

  it 'raises if not initialized with all its data' do
    expect { Accounting::Events::BirthdayMoneyReceived.new }.to raise_error(/required .*:amount/)
  end

  it 'raises if trash data is given' do
    expect do
      Accounting::Events::BirthdayMoneyReceived.new(amount: 100, person_name: 'jackson', from: 'bro')
    end.to raise_error(/unexpected parameter from/)
  end
end
