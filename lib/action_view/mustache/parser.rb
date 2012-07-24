require 'action_view'
require 'action_view/mustache'
require 'mustache'
require 'strscan'

module ActionView
  class Mustache < ::Mustache
    class Parser < ::Mustache::Parser
      def initialize(options = {})
        @options = {}
      end

      def compile(template)
        if template.respond_to?(:encoding)
          @encoding = template.encoding
          template = template.dup.force_encoding("BINARY")
        else
          @encoding = nil
        end

        @sections = []
        @result = [:multi]
        @scanner = StringScanner.new(template)

        until @scanner.eos?
          scan_tags || scan_text
        end

        if !@sections.empty?
          type, pos, result = @sections.pop
          error "Unclosed section #{type.inspect}", pos
        end

        @result
      end

      def scan_tags
        start_of_line = @scanner.beginning_of_line?
        pre_match_position = @scanner.pos
        last_index = @result.length

        return unless x = @scanner.scan(/([ \t]*)?#{Regexp.escape(otag)}/)
        padding = @scanner[1] || ''

        unless start_of_line
          @result << [:static, padding] unless padding.empty?
          pre_match_position += padding.length
          padding = ''
        end

        current_ctag = self.ctag
        type = @scanner.scan(/#|\^|\/|=|!|<|>|&|\{/)
        @scanner.skip(/\s*/)

        if ANY_CONTENT.include?(type)
          r = /\s*#{regexp(type)}?#{regexp(current_ctag)}/
          content = scan_until_exclusive(r)
        else
          content = @scanner.scan(ALLOWED_CONTENT)
        end

        error "Illegal content in tag" if content.empty?

        fetch = [:mustache, :fetch, content.split('.'), offset]
        prev = @result

        case type
        when '#'
          block = [:multi]
          @result << [:mustache, :section, fetch, block, offset]
          @sections << [content, position, @result]
          @result = block
        when '^'
          block = [:multi]
          @result << [:mustache, :inverted_section, fetch, block, offset]
          @sections << [content, position, @result]
          @result = block
        when '/'
          section, pos, result = @sections.pop
          raw = @scanner.pre_match[pos[3]...pre_match_position] + padding
          (@result = result).last << raw << [self.otag, self.ctag]

          if section.nil?
            error "Closing unopened #{content.inspect}"
          elsif section != content
            error "Unclosed section #{section.inspect}", pos
          end
        when '!'
        when '='
          self.otag, self.ctag = content.split(' ', 2)
        when '>', '<'
          @result << [:mustache, :partial, content, padding, offset]
        when '{', '&'
          type = "}" if type == "{"
          @result << [:mustache, :utag, fetch, offset]
        else
          @result << [:mustache, :etag, fetch, offset]
        end

        @scanner.skip(/\s+/)
        @scanner.skip(regexp(type)) if type

        unless close = @scanner.scan(regexp(current_ctag))
          error "Unclosed tag"
        end

        if start_of_line && !@scanner.eos?
          if @scanner.peek(2) =~ /\r?\n/ && SKIP_WHITESPACE.include?(type)
            @scanner.skip(/\r?\n/)
          else
            prev.insert(last_index, [:static, padding]) unless padding.empty?
          end
        end

        @sections.last[1] << @scanner.pos unless @sections.empty?

        return unless @result == [:multi]
      end

      def scan_text
        text = scan_until_exclusive(/(^[ \t]*)?#{Regexp.escape(otag)}/)

        if text.nil?
          text = @scanner.rest
          @scanner.terminate
        end

        text.force_encoding(@encoding) if @encoding

        @result << [:static, text] unless text.empty?
      end

      def scan_until_exclusive(regexp)
        pos = @scanner.pos
        if @scanner.scan_until(regexp)
          @scanner.pos -= @scanner.matched.size
          @scanner.pre_match[pos..-1]
        end
      end

      def offset
        position[0, 2]
      end

      def position
        rest = @scanner.check_until(/\n|\Z/).to_s.chomp

        parsed = @scanner.string[0...@scanner.pos]

        lines = parsed.split("\n")

        [ lines.size, lines.last.size - 1, lines.last + rest ]
      end

      def regexp(thing)
        /#{Regexp.escape(thing)}/
      end
    end
  end
end
