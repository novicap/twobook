module Twobook
  class Configuration
    attr_accessor :accounting_namespace
  end

  def self.configuration
    @configuration
  end

  def self.configure
    @configuration ||= Configuration.new
    yield(@configuration)
  end

  configure do |config|
    config.accounting_namespace = 'Accounting'
  end
end
