RSpec.describe Medici::Account do
  it 'initializes' do
    account = described_class.new
    expect(account.name).to eq 'medici/account'
  end
end
