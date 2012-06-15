require 'action_view'
require 'mustache'

module ActionView
  # Public: Mustache View base class.
  #
  # All Mustache views MUST inherit from this class.
  #
  # Examples
  #
  #     module Layouts
  #       class Application < ActionView::Mustache; end
  #     end
  #
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

    # Internal: Initializes Mustache View.
    #
    # Initialization is handled by MustacheHelper#mustache_view.
    #
    # view - ActionView::Base instance
    #
    # Returns ActionView::Mustache instance.
    def initialize(view)
      # Reference to original ActionView context.
      @_view = view

      # Grab template path from view
      self.template_name = view.instance_variable_get(:@virtual_path)

      # If view has an associated controller
      if controller = view.controller
        # Copy controller ivars into our view
        controller.view_assigns.each do |name, value|
          instance_variable_set '@'+name, value
        end
      end

      # Define `yield` keyword for content_for :layout
      context[:yield] = lambda { content_for :layout }
    end

    # Remove Mustache's render method so ActionView's render can be
    # delegated to.
    undef_method :render

    # Public: Get view context.
    #
    # Returns ActionView::Mustache::Context instance.
    def context
      @context ||= Context.new(self)
    end

    # Public: Forwards methods to original Rails view context
    #
    # Returns an Object.
    def method_missing(*args, &block)
      @_view.send(*args, &block)
    end

    # Public: Checks if method exists in Rails view context.
    #
    # Returns Boolean.
    def respond_to?(method, include_private = false)
      super || @_view.respond_to?(method, include_private)
    end
  end
end
