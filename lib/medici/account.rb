module Medici
  class Account
    ACCOUNT_TYPES = %i(assets liabilities revenue expenses records)

    attr_reader :name, :balance, :data, :tags, :entries, :ledger

    def initialize(balance: 0, **data)
      @balance = Medici.wrap_number(balance)
      @entries = []

      @data = data
      @name = define_name

      valid_data = self.class.name_includes + self.class.has
      data.keys.each do |key|
        raise "Invalid data #{key} for #{self.class.category}" unless key.in?(valid_data)
      end
    end

    def clone
      c = super
      c.instance_variable_set(:@entries, @entries.map(&:clone))
      c.instance_variable_set(:@data, @data.deep_dup)
      c
    end

    def <<(other)
      raise 'Can only append entries to accounts' unless other.is_a?(Entry)

      @entries << other
      @entries.sort_by!(&:event)
      @balance = Medici.wrap_number(@balance + other.amount)
      update_mutable_data(other.data)
      self
    end

    def +(other)
      clone << other
    end

    # Account equality is based only on name, which must be unique
    def ==(other)
      @name == other.name
    end
    alias eql? ==

    def hash
      @name.hash
    end

    def update_mutable_data(data)
      validate_data_mutable(data)
      @data = @data.merge(data).sort.to_h
      self
    end

    def validate_data_mutable(new_data)
      new_data.keys.each do |k|
        raise "Attribute #{k} cannot be modified in #{inspect}" if k.in?(self.class.name_includes)
        raise "Unknown parameter #{k} given to #{inspect}" unless k.in?(self.class.has)
      end
    end

    def inspect
      inspected_balance = @balance.to_f
      "<#{self.class.name} @name=#{@name} @balance=#{inspected_balance} entry_count=#{@entries.count}>"
    end

    def self.category
      name.underscore.gsub("#{Medici.configuration.accounting_namespace.underscore}/accounts/", '')
    end

    def self.types
      Utilities.types(Medici::Account)
    end

    def self.tagged?(tag)
      if tag.is_a?(Array)
        tag.empty? || tag.all? { |t| tagged?(t) }
      else
        tags.include?(tag)
      end
    end

    def self.account_type(*args)
      return @account_type if args.empty?
      unless args.first.in?(ACCOUNT_TYPES)
        raise "Invalid account type #{args.first} for #{name}. Valid types: #{ACCOUNT_TYPES}"
      end
      @account_type = args.first
    end

    def self.name_includes(*args)
      @name_includes ||= []
      return @name_includes if args.empty?
      @name_includes += args
    end

    def self.tags(*args)
      @tags ||= []
      return @tags if args.empty?
      @tags += args
    end

    def self.has(*args)
      @has ||= []
      return @has if args.empty?
      @has += args
    end

    def self.description(*args)
      @description ||= ''
      return @description if args.empty?
      @description = args.first
    end

    private

    def define_name
      default = self.class.category
      custom_parts = self.class.name_includes.sort.map do |key|
        value = @data.dig(key)
        raise "Cannot initialize #{self.class.name}: needed #{key}" if value.blank?
        value
      end

      ([default] + custom_parts).join(':')
    end
  end
end
