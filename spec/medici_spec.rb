RSpec.describe Medici do
  it 'has a version number' do
    expect(Medici::VERSION).not_to be nil
  end

  it 'patches and wraps numbers with BigDecimal' do
    number = Medici.wrap_number(10 / 3.0)
    expect(number).to eq 3.333333
    expect(number.as_json).to eq 3.333333
    expect(number.inspect).to include('3.333333')
  end
end
