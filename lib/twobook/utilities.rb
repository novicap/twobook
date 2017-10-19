module Twobook
  module Utilities
    def self.match_params(method, available, error_message)
      required = method.parameters.select { |p| p.first == :keyreq }.map(&:second)
      optional = method.parameters.select { |p| p.first == :key }.map(&:second)

      if method.parameters.any? { |p| p.first == :req || p.first == :opt }
        raise "match_params only works with named parameters (was given #{method.parameters})"
      end

      missing = required - available.keys
      raise "#{error_message} - missing parameters #{missing}" if missing.any?

      params = available.slice(*(required + optional))
      if params.any?
        method.call(params)
      else
        method.call
      end
    end

    # Lists all the leaf node descendants of a class.
    # The files must already be loaded.
    def self.types(klass, cache = false)
      if cache
        @types_cache ||= {}
        return @types_cache[klass.name] ||= begin
            klass.descendants
                 .reject { |k| k.name.nil? || k.subclasses.reject { |s| s.name.nil? }.any? }
                 .sort_by(&:name)
          end
      end

      klass.descendants
           .reject { |k| k.name.nil? || k.subclasses.reject { |s| s.name.nil? }.any? }
           .sort_by(&:name)
    end
  end
end
