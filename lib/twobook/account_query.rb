module Twobook
  class AccountQuery
    def after(event)
      @after = event
      self
    end

    def none?
      false
    end

    def execute(array)
      array
    end

    def and(other)
      AndQuery.new(self, other)
    end
    alias & and

    def or(other)
      OrQuery.new(self, other)
    end
    alias | or

    def where(constraints)
      WhereQuery.new(self, constraints)
    end

    def named(constraints)
      WhereQuery.new(self, constraints).convert_to_name_query
    end

    def none
      NoneQuery.new
    end

    def self.where(constraints)
      new.where(constraints)
    end

    def self.named(constraints)
      new.named(constraints)
    end

    def self.none
      new.none
    end

    class NoneQuery < AccountQuery
      def execute(_)
        []
      end

      def none?
        true
      end
    end

    class WhereQuery < AccountQuery
      ATTRIBUTE_CONSTRAINTS = %i(ledger name)
      CLASS_CONSTRAINTS = %i(category account_type)

      def initialize(child_query, original_constraints)
        constraints = original_constraints.deep_dup

        # Slice up the constraints into types
        @attribute_constraints = constraints.extract!(*ATTRIBUTE_CONSTRAINTS)
        @class_constraints = constraints.extract!(*CLASS_CONSTRAINTS)

        # Support category shorthand and check it exists
        # e.g. "sme/liabilities/payout" instead of Accounting::Accounts::Sme::Liabilities::Payout.name
        category = @attribute_constraints[:category]
        if category.present?
          unless category_name.in?(Twobook::Account.types.map { |t| t.class.category })
            raise "Invalid category: #{category}"
          end
        end

        @balance_constraint = constraints.delete(:balance)
        @tags_constraint = constraints.delete(:tags)
        @data_constraints = constraints

        @child_query = child_query
      end

      def none?
        @child_query.none?
      end

      def execute(array)
        @child_query.execute(array).select do |account|
          next unless matches_attributes(account)
          next unless matches_class(account)
          next unless matches_data(account)
          next unless matches_balance(account)

          next if @tags_constraint && !account.class.tagged?(@tags_constraint)

          true
        end
      end

      def category
        @class_constraints[:category]
      end

      def data
        @data_constraints
      end

      def convert_to_name_query
        if @attribute_constraints[:name].present?
          NameQuery.new(@attribute_constraints[:name])
        else
          account = construct_account
          NameQuery.new(account.name, account: construct_account)
        end
      end

      def construct_account
        klass = Account.types.detect { |t| t.category == category }
        raise "Can't find matching class for category #{category}" unless klass.present?
        klass.new(balance: 0, **data)
      end

      def inspect
        "<#{self.class.name} @attribute_constraints=#{@attribute_constraints} " \
          "@class_constraints=#{@class_constraints} " \
          "@data_constraints=#{@data_constraints} " \
          "@tags_constraint=#{@tags_constraint || 'nil'}>"
      end

      private

      def matches_data(account)
        account_data = account.data.to_a
        @data_constraints.none? { |pair| !pair.in?(account_data) }
      end

      def matches_attributes(account)
        @attribute_constraints.none? { |k, v| account.public_send(k) != v }
      end

      def matches_class(account)
        @class_constraints.none? { |k, v| account.class.public_send(k) != v }
      end

      def matches_balance(account)
        return true if @balance_constraint.nil?
        return account.balance.positive? if @balance_constraint == :positive
        account.balance == @balance_constraint
      end
    end

    class NameQuery < AccountQuery
      attr_reader :name

      def initialize(name, account: nil)
        @name = name
        @account = account
      end

      def construct_account
        raise 'Could not construct an account from this name query: no data or category' if @account.nil?
        @account
      end

      def execute(accounts)
        accounts.select { |account| account.name == @name }
      end
    end

    class AndQuery < AccountQuery
      attr_reader :first, :second

      def initialize(first, second)
        @first = first
        @second = second
      end

      def execute(array)
        @first.execute(array) & @second.execute(array)
      end

      def none?
        @first.none? || @second.none?
      end
    end

    class OrQuery < AccountQuery
      attr_reader :first, :second

      def initialize(first, second)
        @first = first
        @second = second
      end

      def none?
        @first.none? && @second.none?
      end

      def execute(array)
        @first.execute(array) | @second.execute(array)
      end
    end
  end
end
