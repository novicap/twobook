module Twobook
  class Handler
    # Mixin for Handler with some query shorthand.
    # Expects @accounts_in_process to be set when running a handler
    # Expects @data_in_process to be set when looking up account requirements
    module QueryHelpers
      def one(query)
        { requested: :one, query: query.convert_to_name_query }
      end

      def existing(query)
        { requested: :existing, query: query.convert_to_name_query }
      end

      def many(query)
        { requested: :many, query: query }
      end

      def where(constraints)
        AccountQuery.where(constraints)
      end

      def satisfy_requirement(requested:, query:)
        accounts = query.execute(@accounts_in_process)

        case requested
        when :one
          existing = accounts.first
          return existing if existing.present?
          new = query.construct_account
          @accounts_in_process << new
          new
        when :existing
          it = accounts.first
          if it.nil?
            raise "Cannot process #{@event_in_process.inspect} with #{inspect}: " \
              "no match for query #{query.inspect}). I have #{@accounts_in_process.join(', ')}"

          end
          it
        when :many
          Twobook.wrap_account_list!(accounts)
        else
          raise "Cannot satisfy requirement request #{requested}: not supported"
        end
      end

      def respond_to_missing?(account_name, *_)
        account_name.to_s =~ /_accounts?$/
      end

      def method_missing(account_label, *_)
        super unless account_label.to_s =~ /_accounts?$/
        super if @event_in_process.blank?

        requirement = labelled_account_requirements.dig(account_label)
        super unless requirement

        satisfy_requirement(requirement)
      end

      def labelled_account_requirements
        them = Utilities.match_params(
          method(:accounts), @data_in_process, "Cannot generate accounts for #{inspect} with data #{@data_in_process}"
        )

        them.keys.map(&:to_s).each do |k|
          raise "Invalid account label #{k} for #{inspect} (must end in _account(s))" unless k =~ /_accounts?/
        end

        them
      end

      def account_requirements
        labelled_account_requirements.values
      end

      def accounts(*_)
        {}
      end
    end
  end
end
