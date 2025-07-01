require_relative "dsl_proxy"
require_relative "dsl_builder_context"
require_relative "../syntax/schema"

module TraitEngine
  module Parser
    module Dsl
      def self.build_schema(&block)
        context = DslBuilderContext.new
        proxy   = DslProxy.new(context)
        proxy.instance_eval(&block)
        Syntax::Schema.new(
          context.attributes,
          context.traits,
          context.functions
        )
      end

      class << self
        alias schema build_schema
      end

      # –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
      # instance method for classes/modules that `extend TraitEngine::Parser::Dsl`
      #
      #   class MyThing
      #     extend TraitEngine::Parser::Dsl
      #     schema { … }
      #   end
      #
      def schema(&block)
        @__schema__ = TraitEngine::Parser::Dsl.build_schema(&block)
      end

      def generated_schema
        @__schema__
      end
    end
  end
end
