require 'bigdecimal'

class BigDecimal
  # Makes it easier to work with these in a repl
  def inspect
    "#<BigDecimal '#{to_f}'>"
  end

  def as_json(*_)
    truncate(Twobook::SCALE).to_f
  end
end

module Twobook
  ::BigDecimal.mode(::BigDecimal::ROUND_MODE, ::BigDecimal::ROUND_HALF_EVEN)
  PRECISION = 15 # significant figures
  SCALE = 6 # decimals after the point

  def self.wrap_number(n)
    ::BigDecimal.new(n, PRECISION).round(SCALE)
  end
end
