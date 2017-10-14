RSpec.describe Medici::Account do
  it 'initializes' do
    account = described_class.new
    expect(account.name).to eq 'medici/account'
  end

  context 'when I have an account' do
    let!(:account) { Accounting::Accounts::CurrentAccount.new(person_name: 'jackson') }

    it 'has the right name' do
      expect(account.name).to eq 'current_account:jackson'
    end

    it 'has the right category' do
      expect(account.class.category).to eq 'current_account'
    end

    it 'has an account type' do
      expect(account.class.account_type).to eq :assets
    end

    it 'has a default balance' do
      expect(account.balance).to eq 0
    end
  end

  it 'raises unless I initialize with all name data' do
    expect { Accounting::Accounts::CurrentAccount.new }.to raise_error(/needed person_name/)
  end

  it 'raises if I give it trash data' do
    expect do
      Accounting::Accounts::CurrentAccount.new(person_name: 'jackson', attribute: 'sad')
    end.to raise_error(/Invalid data attribute/)
  end

  it 'can have optional data' do
    expires = 1.day.from_now
    account = Accounting::Accounts::CreditCard.new(person_name: 'jackson', expires_at: expires)
    expect(account.data[:expires_at]).to eq expires
  end
end
