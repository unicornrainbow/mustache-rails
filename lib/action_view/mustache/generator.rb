require 'action_view'
require 'action_view/mustache'
require 'mustache'

module ActionView
  class Mustache < ::Mustache
    # Public: Compiles tokens from Mustache::Parser into evaluatable
    # Ruby code.
    #
    # The code generate targets Rails output buffer and must be
    # evaluated inside an ActionView::Base instance.
    #
    # See Mustache::Generator for more info.
    class Generator
      # Public: Convert tokens to plain old Ruby.
      #
      # exp - Array of tokens produced by Mustache::Parser
      #
      # Returns String of compiled Ruby code.
      def compile(exp)
        @line_number = 1
        src = ""
        src << "@output_buffer = output_buffer || ActionView::OutputBuffer.new; "
        src << compile!(exp)
        src << "@output_buffer.to_s;"
        src
      end

      # Internal: Recursively compile token expression.
      #
      # exp - Token Array structure
      #
      # Returns String.
      def compile!(exp)
        case exp.first
        when :multi
          exp[1..-1].map { |e| compile!(e) }.join
        when :static
          text(exp[1])
        when :mustache
          send("on_#{exp[1]}", *exp[2..-1])
        else
          raise "Unhandled exp: #{exp.first}"
        end
      end

      # Internal: Compile section.
      #
      # name    - String of section name
      # content - Array of section content tokens
      #
      # Returns String.
      def on_section(name, content, raw, delims, offset)
        "v = #{compile!(name)}; ctx._eval_section(@output_buffer, v) { #{compile!(content)} }; "
      end

      # Internal: Compile inverted section.
      #
      # name    - String of section name
      # content - Array of section content tokens
      #
      # Returns String.
      def on_inverted_section(name, content, raw, delims, offset)
        "v = #{compile!(name)}; ctx._eval_inverted_section(@output_buffer, v) { #{compile!(content)} }; "
      end

      # Internal: Compile partial render call.
      #
      # name        - String of partial name
      # indentation - String of indentation level
      #
      # Returns String.
      def on_partial(name, indentation, offset)
        "@output_buffer.concat(render(:partial => #{name.inspect}));"
      end

      # Internal: Compile unescaped tag.
      #
      # name - String name of tag
      #
      # Returns String.
      def on_utag(name, offset)
        "#{newlines(offset[0])}v = #{compile!(name)}; ctx._eval_utag(@output_buffer, v); "
      end

      # Internal: Compile escaped tag.
      #
      # name - String name of tag
      #
      # Returns String.
      def on_etag(name, offset)
        "#{newlines(offset[0])}v = #{compile!(name)}; ctx._eval_etag(@output_buffer, v); "
      end

      # Internal: Compile fetch lookup.
      #
      # names - Array of names to fetch.
      #
      # Returns String.
      def on_fetch(names, offset)
        names = names.map { |n| n.to_sym }

        if names.length == 0
          "ctx[:to_s]"
        elsif names.length == 1
          "ctx[#{names.first.to_sym.inspect}]"
        else
          initial, *rest = names
          "#{rest.inspect}.inject(ctx[#{initial.inspect}]) { |v, k| v && ctx.find(v, k) }; "
        end
      end

      # Internal: Compile static string.
      #
      # text - String of text.
      #
      # Returns String.
      def text(text)
        # text = text.gsub(/['\\]/, '\\\\\&')
        "@output_buffer.safe_concat(#{text.inspect}); "
      end

      def newlines(lineno)
        s = ""
        until lineno == @line_number
          s += "\n"
          @line_number += 1
        end
        s
      end
    end
  end
end
