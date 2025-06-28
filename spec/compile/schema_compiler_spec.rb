require "trait_engine/compile/schema_compiler"
require "trait_engine/syntax/value_descriptor"
require "trait_engine/syntax/location"
require "trait_engine/syntax/nodes/schema"
require "trait_engine/syntax/nodes/trait"
require "trait_engine/syntax/nodes/function"
require "trait_engine/syntax/nodes/attribute"
require "trait_engine/syntax/nodes/conditional_case"

ValueDescriptor = TraitEngine::Syntax::ValueDescriptor
Location = TraitEngine::Syntax::Location
Schema = TraitEngine::Syntax::Nodes::Schema
Trait = TraitEngine::Syntax::Nodes::Trait
Function = TraitEngine::Syntax::Nodes::Function
ConditionalCase = TraitEngine::Syntax::Nodes::ConditionalCase
AttributeNode = TraitEngine::Syntax::Nodes::Attribute
Runtime = TraitEngine::Runtime

RSpec.describe TraitEngine::Compile::SchemaCompiler do
  let(:compile) { described_class.method(:compile) }

  context "with empty AST" do
    let(:ast) { Schema.new(traits: [], functions: [], attributes: [], loc: nil) }
    it "returns a schema with no entries" do
      schema = compile.call(ast)
      expect(schema.traits).to be_empty
      expect(schema.functions).to be_empty
      expect(schema.attributes).to be_empty
    end
  end

  context "trait compilation" do
    # build a single TraitNode for: age >= 18
    let(:loc) { Location.new(file: "x", line: 1, column: 1) }
    let(:pred_desc) do
      { lhs: ValueDescriptor.new(type: :field, value: :age),
        op: :gte,
        rhs: ValueDescriptor.new(type: :literal, value: 18) }
    end
    let(:trait_node) { Trait.new(name: :adult, predicate_descriptor: pred_desc, loc: loc) }
    let(:ast)  { Schema.new(traits: [trait_node], functions: [], attributes: [], loc: loc) }

    it "builds a Runtime::Trait with working predicate" do
      schema = compile.call(ast)
      t = schema.traits[:adult]
      expect(t).to be_a(Runtime::Trait)
      expect(t.call(age: 20)).to be true
      expect(t.call(age: 17)).to be false
    end
  end

  context "function compilation" do
    # stub a shared helper
    before { TraitEngine::SharedFunctions::REGISTRY[:sum] = ->(a, b) { a + b } }

    let(:loc) { Location.new(file: "x", line: 1, column: 1) }
    let(:fn_node) do
      # arguments: [ {type: :literal, value: 5}, {type: :field, value: :x} ]
      args = [
        ValueDescriptor.new(type: :literal,   value: 5),
        ValueDescriptor.new(type: :field,     value: :x)
      ]
      Function.new(name: :adder, method_name: :sum, arg_descriptors: args, loc: loc)
    end
    let(:ast) { Schema.new(traits: [], functions: [fn_node], attributes: [], loc: loc) }

    it "builds a Runtime::Function that sums literal and field" do
      schema = compile.call(ast)
      fn = schema.functions[:adder]
      expect(fn).to be_a(Runtime::Function)

      result = fn.call(double("processor", schema: schema), { x: 7 })
      expect(result).to eq(12)
    end
  end

  context "attribute compilation" do
    let(:loc) { Location.new(file: "x", line: 1, column: 1) }

    it "compiles a simple field attribute" do
      # attribute: name: field:name
      case_node = ConditionalCase.new(
        trait_names: [],
        resolver_descriptor: ValueDescriptor.new(type: :field, value: :name),
        loc: loc
      )
      attr_node = AttributeNode.new(
        name: :name,
        cases: [case_node],
        loc: loc
      )
      ast = Schema.new(traits: [], functions: [], attributes: [attr_node], loc: loc)

      schema = compile.call(ast)
      attr = schema.attributes[:name]
      expect(attr).to be_a(Runtime::Attribute)
      expect(attr.resolver).to be_a(Runtime::Resolvers::Field)
      expect(attr.value(double("processor", schema: schema), { name: "Alice" }, {})).to eq("Alice")
    end

    it "compiles a conditional attribute decision table" do
      # if adult -> literal:"OK", else literal:"NO"
      ok_desc = ValueDescriptor.new(type: :literal, value: "OK")
      no_desc = ValueDescriptor.new(type: :literal, value: "NO")
      row1 = ConditionalCase.new(
        trait_names: [:adult], resolver_descriptor: ok_desc, loc: loc
      )
      row2 = ConditionalCase.new(
        trait_names: [], resolver_descriptor: no_desc, loc: loc
      )
      attr_node = AttributeNode.new(
        name: :status, cases: [row1, row2], loc: loc
      )
      ast = Schema.new(traits: [], functions: [], attributes: [attr_node], loc: loc)

      schema = compile.call(ast)
      attr = schema.attributes[:status]
      expect(attr.table).to be_a(Runtime::DecisionTable)
      expect(attr.table.rows.size).to eq(2)
      expect(attr.value(double("processor", schema: schema), {}, [:adult])).to eq("OK")
      expect(attr.value(double("processor", schema: schema), {}, [])).to eq("NO")
    end
  end
end
