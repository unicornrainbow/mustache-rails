require 'action_view'
require 'action_view/template'
require 'action_view/template/handlers'
require 'action_view/helpers/mustache_helper'
require 'action_view/mustache'
require 'action_view/mustache/generator'
require 'mustache'
require 'digest/md5'

module ActionView
  class Template
    module Handlers
      # Public: Mustache template compiler.
      #
      # Requiring this file should automatically register the template
      # handler, so there should be no need to reference the class
      # directly.
      class Mustache
        # Public: Compile template into Ruby.
        #
        # template - ActionView::Template object
        #
        # Returns String of Ruby code to be evaled.
        def self.call(template)
          # Use standard mustache parser to generate tokens
          tokens = ::Mustache::Parser.new.compile(template.source)

          # Use custom generator to generate the compiled ruby
          src = ActionView::Mustache::Generator.new.compile(tokens)

          digest = Digest::MD5.hexdigest(template.source)[0, 10]
          set_cache_key = "merge({:template_cache_key => \"#{digest}\"})"

          <<-RUBY
            ctx = mustache_view.context; ctx.push(local_assigns.#{set_cache_key}); #{src}
          RUBY
        end
      end
    end

    register_template_handler :mustache, Handlers::Mustache
  end
end
