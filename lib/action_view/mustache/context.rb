require 'action_view'
require 'mustache'

module ActionView
  class Mustache < ::Mustache
    # Internal: Override Mustache's default Context class
    class Context < ::Mustache::Context
      # Partials are no longer routed through Mustache but through
      # ActionView's own render method.
      undef_method :partial

      # Escape helper isn't used, its all handled by Rails' SafeBuffer
      # auto escaping.
      undef_method :escapeHTML

      # Internal: Evaluate section block.
      #
      # buffer - ActiveSupport::SafeBuffer object
      # value  - Object value of section tag
      #
      # Returns nothing.
      def _eval_section(buffer, value, &block)
        if value
          if value == true
            yield
          elsif value.is_a?(Proc)
            buffer.concat(v.call { capture(&block) }.to_s)
          else
            value = [value] unless value.is_a?(Array) || defined?(Enumerator) && value.is_a?(Enumerator)
            for h in value
              push(h)
              yield
              pop
            end
          end
        end
      end

      # Internal: Evaluate inverted section block.
      #
      # buffer - ActiveSupport::SafeBuffer object
      # value  - Object value of inverted section tag
      #
      # Returns nothing.
      def _eval_inverted_section(buffer, value)
        if (value.nil? || value == false || value.respond_to?(:empty?) && value.empty?)
          yield
        end
      end

      # Internal: Evaluate unescaped tag.
      #
      # buffer - ActiveSupport::SafeBuffer object
      # value  - Object value of tag
      #
      # Returns nothing.
      def _eval_utag(buffer, value)
        value = value.call.to_s if value.is_a?(Proc)
        buffer.safe_concat(value.to_s)
      end

      # Internal: Evaluate escaped tag.
      #
      # buffer - ActiveSupport::SafeBuffer object
      # value  - Object value of tag
      #
      # Returns nothing.
      def _eval_etag(buffer, value)
        value = value.call.to_s if value.is_a?(Proc)
        buffer.concat(value.to_s)
      end
    end
  end
end
