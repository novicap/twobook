RSpec.describe Twobook::Corrections do
  context 'when some events have happened' do
    let!(:now) { Time.current }

    let(:agreement) { Accounting::Agreements::SavingsScheme.new(saving_percentage: 0.1) }

    def make_event(amount = 1000, happened_at: now)
      event = Accounting::Events::BirthdayMoneyReceived.new(
        amount: amount,
        person_name: 'jackson',
        happened_at: happened_at,
      )
      event.agreements = [agreement]
      event
    end

    let(:events) do
      [
        make_event(1000, happened_at: now - 5.days),
        make_event(1500, happened_at: now - 3.days),
        make_event(2000, happened_at: now),
      ]
    end

    let(:accounts) do
      Twobook.simulate(events, [])
    end

    it 'knows the balance of accounts at various points in time' do
      current_account = Twobook::AccountQuery.where(
        category: 'current_account',
      ).on(accounts).first

      expect(current_account.balance).to eq 4050
      expect(current_account.balance_before(now - 5.days)).to eq 0
      expect(current_account.balance_before_event(events.first)).to eq 0
      expect(current_account.balance_before(now - 3.days)).to eq 900
      expect(current_account.balance_before_event(events.second)).to eq 900
      expect(current_account.balance_before(now)).to eq 2250
      expect(current_account.balance_before_event(events.third)).to eq 2250
    end

    it 'can create a deletion correction' do
      event = described_class.make_deletion(events.first, accounts, events)
      results = Twobook.simulate(event.load!, accounts)

      expect_account_balances results, [
        'current_account:jackson', 3150,
        'birthday_money:jackson', 3500,
        'savings:jackson', 350,
        'twobook/corrections/correction_buffer', 0,
      ]
    end

    it 'can create an edit correction' do
      correct_event = events.first
      correct_event.data[:amount] = 500
      event = described_class.make_edit(correct_event, accounts, events)
      results = Twobook.simulate(event.load!, accounts)

      expect_account_balances results, [
        'current_account:jackson', 3600,
        'birthday_money:jackson', 4000,
        'savings:jackson', 400,
        'twobook/corrections/correction_buffer', 0,
      ]
    end
  end
end
