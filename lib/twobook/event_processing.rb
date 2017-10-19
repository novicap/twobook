module Twobook
  def self.simulate(event, input_accounts = [])
    return simulate_chain(event, input_accounts) if event.is_a?(Array)
    raise 'Cannot simulate: event has no agreements' unless event.agreements.any?

    handlers = event.agreements.reduce([]) do |memo, agreement|
      memo + agreement.handlers_for(event)
    end

    new_accounts = handlers.reduce(Set.new(input_accounts)) do |processing_accounts, handler|
      handler.run(processing_accounts)
    end

    # All entries added while processesing that event should satisfy the accounting equation.
    ensure_transaction! new_accounts, event

    new_accounts
  end

  def self.simulate_chain(events, input_accounts = [])
    sorted_groups = events.group_by(&:happened_at)
    sorted = []
    sorted_groups.keys.sort.each do |time|
      group = sorted_groups[time]
      # Assign order to groups of events with the same timestamp according to the order passed in
      sorted_group = if group.any? { |event| event.partial_order.nil? }
                       group.map.with_index { |event, i| event.update_partial_order(i) }
                     else
                       group.sort_by(&:partial_order)
                     end
      sorted_group.each { |event| sorted << event }
    end

    sorted.reduce(input_accounts) do |accounts, event|
      simulate(event, accounts)
    end
  end

  def self.ensure_transaction!(accounts, event)
    assets = sum_entries_under_account_type(:assets, accounts, event)
    liabilities = sum_entries_under_account_type(:liabilities, accounts, event)
    revenue = sum_entries_under_account_type(:revenue, accounts, event)
    expenses = sum_entries_under_account_type(:expenses, accounts, event)

    sum = assets - liabilities - revenue + expenses

    if sum.nonzero?
      report = accounts.map do |a|
        "#{a.name}: #{a.entries.select { |e| e.event == event }.map(&:amount).sum}"
      end.join("\n")

      raise "Invalid transaction: must sum to zero, but summed to #{sum}. \n#{report}"
    end
  end

  def self.sum_entries_under_account_type(type, accounts, event)
    accounts.select { |a| a.class.account_type == type }.map do |a|
      a.entries.select { |e| e.event == event }.map(&:amount).sum
    end.sum
  end
end
