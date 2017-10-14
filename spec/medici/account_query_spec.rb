RSpec.describe Medici::AccountQuery do
  def test(**query)
    described_class.where(query).execute(accounts)
  end

  context 'when we have a few accounts' do
    let(:now) { Time.current }

    let!(:accounts) do
      [
        Accounting::Accounts::CreditCard.new(person_name: 'jackson', expires_at: now + 1.day),
        Accounting::Accounts::CurrentAccount.new(person_name: 'medusa'),
        Accounting::Accounts::InterestFromCreditCard.new(person_name: 'medusa', balance: 100),
      ]
    end

    it 'finds accounts by type' do
      expect(test(account_type: :assets)).to eq [accounts[1]]
    end

    it 'finds accounts by category' do
      expect(test(category: 'credit_card')).to eq [accounts[0]]
    end

    it 'finds accounts by data' do
      expect(test(person_name: 'medusa')).to eq [accounts[1], accounts[2]]
      expect(test(expires_at: now + 1.day)).to eq [accounts[0]]
    end

    it 'does an AND chain correctly' do
      query = described_class.where(account_type: :expenses).and(
        described_class.where(person_name: 'medusa'),
      )
      expect(query.execute(accounts)).to eq [accounts[2]]
    end

    it 'does an OR chain correctly' do
      query = described_class.where(account_type: :expenses).or(
        described_class.where(person_name: 'medusa'),
      )
      expect(query.execute(accounts)).to eq [accounts[2], accounts[1]]
    end
  end
end
