# frozen_string_literal: true

require "spec_helper"

module TraitEngine
  module Syntax
    RSpec.describe Location do
      it "stores file, line and column" do
        loc = described_class.new(file: "foo.rb", line: 10, column: 5)
        expect(loc.file).to eq("foo.rb")
        expect(loc.line).to eq(10)
        expect(loc.column).to eq(5)
      end
    end

    RSpec.describe Node do
      it "defaults loc to nil" do
        expect(described_class.new.loc).to be_nil
      end

      it "accepts and exposes a loc passed to initializer" do
        loc = Location.new(file: "a.rb", line: 1, column: 2)
        node = described_class.new(loc: loc)
        expect(node.loc).to be(loc)
      end
    end

    RSpec.describe Schema do
      it "is a Node and exposes its attributes, traits and functions" do
        attributes = double(:attributes)
        traits     = double(:traits)
        functions  = double(:functions)
        schema = described_class.new(attributes: attributes, traits: traits, functions: functions, loc: nil)

        expect(schema).to be_a(Node)
        expect(schema.attributes).to eq(attributes)
        expect(schema.traits).to eq(traits)
        expect(schema.functions).to eq(functions)
      end
    end

    RSpec.describe Attribute do
      it "is a Node and exposes name and value" do
        literal   = Literal.new(value: "bar")
        attribute = described_class.new(name: :foo, expression: literal)

        expect(attribute).to be_a(Node)
        expect(attribute.name).to eq(:foo)
        expect(attribute.expression).to eq(literal)
      end
    end

    RSpec.describe Trait do
      it "is a Node and exposes name and expression" do
        expr  = Literal.new(value: true)
        trait = described_class.new(name: :t, expression: expr)

        expect(trait).to be_a(Node)
        expect(trait.name).to eq(:t)
        expect(trait.expression).to eq(expr)
      end
    end

    RSpec.describe Function do
      it "is a Node and exposes name and body" do
        body     = Literal.new(value: 0)
        function = described_class.new(name: :f, body: body)

        expect(function).to be_a(Node)
        expect(function.name).to eq(:f)
        expect(function.body).to eq(body)
      end
    end

    RSpec.describe Literal do
      it "is a Node and exposes its value" do
        lit = described_class.new(value: "xyz")
        expect(lit).to be_a(Node)
        expect(lit.value).to eq("xyz")
      end
    end

    RSpec.describe Field do
      it "is a Node and exposes its identifier" do
        field = described_class.new(identifier: :id)
        expect(field).to be_a(Node)
        expect(field.identifier).to eq(:id)
      end
    end

    RSpec.describe BindingRef do
      it "is a Node and exposes its name" do
        ref = described_class.new(name: :x)
        expect(ref).to be_a(Node)
        expect(ref.name).to eq(:x)
      end
    end

    RSpec.describe Builder do
      it "is a Node and exposes its steps" do
        steps = [Literal.new(value: 1), Literal.new(value: 2)]
        builder = described_class.new(steps: steps)

        expect(builder).to be_a(Node)
        expect(builder.steps).to eq(steps)
      end
    end

    RSpec.describe CascadeBuilder do
      it "inherits from Builder" do
        expect(described_class < Builder).to be true
      end
    end

    RSpec.describe CallExpression do
      it "is a Node and exposes fn_name and arguments" do
        fn_name = Literal.new(value: :foo)
        arguments = [Literal.new(value: 1)]
        call = described_class.new(fn_name: fn_name, arguments: arguments)

        expect(call).to be_a(Node)
        expect(call.fn_name).to eq(fn_name)
        expect(call.arguments).to eq(arguments)
      end
    end

    RSpec.describe CascadeExpression do
      it "is a Node and exposes receiver and calls" do
        cases = double(:cases)
        default = double(:default)

        cascade = described_class.new(cases: cases, default: default)

        expect(cascade).to be_a(Node)
        expect(cascade.cases).to eq(cases)
        expect(cascade.default).to eq(default)
      end
    end

    RSpec.describe ListExpression do
      it "is a Node and exposes its elements" do
        elements = [Literal.new(value: :a), Literal.new(value: :b)]
        list = described_class.new(elements: elements)

        expect(list).to be_a(Node)
        expect(list.elements).to eq(elements)
      end
    end
  end
end
