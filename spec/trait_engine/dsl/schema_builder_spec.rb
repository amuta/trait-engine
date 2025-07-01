# frozen_string_literal: true

require "spec_helper"
require "trait_engine/dsl/schema_builder"

RSpec.describe TraitEngine::DSL::SchemaBuilder do
  let(:schema) do
    described_class.build do
      attribute :age,           field(:raw_age)
      trait     :is_minor,      ref(:age), :<, 18
      function  :double,        call(:mul, literal(2), field(:raw_age))

      attribute :status do
        on_trait :is_minor, "rejected"
        default "accepted"
      end
    end
  end

  it "produces a Syntax::Schema" do
    expect(schema).to be_a(TraitEngine::Syntax::Schema)
  end

  it "captures attributes, traits, and functions counts" do
    expect(schema.attributes.size).to eq 2 # :age, :status
    expect(schema.traits.size).to eq 1
    expect(schema.functions.size).to eq 1
  end

  it "creates correct nodes for simple attribute expression" do
    age_attr = schema.attributes.find { |a| a.name == :age }
    expect(age_attr.expression).to be_a(TraitEngine::Syntax::Field)
    expect(age_attr.expression.identifier).to eq :raw_age
  end

  it "creates a cascade expression for the block attribute" do
    status_attr = schema.attributes.find { |a| a.name == :status }
    expr = status_attr.expression
    expect(expr).to be_a(TraitEngine::Syntax::CascadeExpression)

    # first case predicate should be BindingRef(:is_minor)
    cond, res = expr.cases.first
    expect(cond).to be_a(TraitEngine::Syntax::BindingRef)
    expect(cond.name).to eq :is_minor
    expect(res.value).to eq "rejected"

    # default literal
    expect(expr.default.value).to eq "accepted"
  end

  it "builds trait expression as CallExpression" do
    trait = schema.traits.first
    call  = trait.expression
    expect(call.fn_name).to eq :<
    expect(call.arguments.map(&:class)).to eq [
      TraitEngine::Syntax::BindingRef,
      TraitEngine::Syntax::Literal
    ]
  end
end
