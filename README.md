````markdown
# TraitEngine   <!-- badges -->  
[![Gem Version](https://badge.fury.io/rb/trait_engine.svg)](https://rubygems.org/gems/trait_engine)  
[![CI](https://github.com/amuta/trait-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/amuta/trait-engine/actions)

**Declarative, trait-driven attribute mapping for Ruby**  
Drop hundreds of ad-hoc `if`/`case` branches. Define your business rules as a simple graph of **5 primitives**, then compile and execute them against any context. Ask “why did I get this value?” and receive a full JSON decision trace.

---

## Why TraitEngine?

| Pain point in typical apps                                  | TraitEngine cure                                                           |
|--------------------------------------------------------------|-----------------------------------------------------------------------------|
| Branching logic scattered through service objects            | Centralize all rules in one `trait`/`attribute` schema                      |
| Fat `if`/`elsif` chains that grow brittle over time          | Add a **trait** once, reuse it across many attributes                       |
| Hard to debug: “Why did promo_code come out wrong?”          | `processor.explain(:promo_code, ctx)` returns a structured trace            |
| Changing rules = code deploy                                | Edit your YAML or Ruby‐DSL and hot-reload via the Rails integration         |
| Custom edge cases require new methods and regressions        | Extend with new **functions** or **traits** without touching core code      |

---

## Installation

```bash
gem install trait_engine
# or in Gemfile
gem "trait_engine"
````

### (Optional) Rails integration

```ruby
# config/application.rb
require "trait_engine/rails"
```

This will autoload your `config/traits/*.yml` and make `TraitEngine::DSL` available in Rails console.

---

## Quick start (Ruby-DSL)

```ruby
require "trait_engine"

schema = TraitEngine::DSL.build do
  # ─── 1) Traits (boolean predicates) ──────────────────────
  trait_definitions do
    gold_tier    :tier,              'gold'
    eu_region    :region,            'EU'
    high_value   :order_total_cents, :greater_than, 10_000
    black_friday :season,            'black_friday'
  end

  # ─── 2) Functions (transformations) ──────────────────────
  function_definitions do
    bf_code :concatenate, literal("BF-"), attribute(:order_id)
  end

  # ─── 3) Attributes (values & cascades) ───────────────────
  attribute_definitions do
    tier              from_field:      :tier
    region            from_field:      :region
    order_total_cents from_field:      :total_cents
    order_id          from_field:      :id
    season            from_identifier: :campaign

    promo_code do
      on_trait  :black_friday,          use_function: :bf_code
      on_traits :gold_tier, :eu_region, use_literal:  "GOLDEU8"
      on_trait  :gold_tier,             use_literal:  "GOLD5"
      default                            use_literal:  "WELCOME"
    end
  end
end

ctx = {
  tier:              "gold",
  region:            "EU",
  total_cents:       13_500,
  id:                421,
  campaign:          "summer_sale"
}

processor = TraitEngine::Processor.new(schema)

puts processor.resolve_attribute(:promo_code, ctx)
# ⇒ "GOLDEU8"

puts processor.explain(:promo_code, ctx).to_json
# {
#   "matched_traits":   ["gold_tier","eu_region","high_value"],
#   "chosen_resolver":  "literal:\"GOLDEU8\"",
#   "dependencies":     ["tier","region","order_total_cents","id"]
# }
```

---

## Loading from YAML

```yaml
# config/traits/promo.yml
traits:
  gold_tier:  attribute:tier == gold
  eu_region:  attribute:region == EU
  high_value: field:order_total_cents > 10000

functions:
  bf_code:
    method: concatenate
    arguments:
      - literal:BF-
      - attribute:order_id

attributes:
  promo_code:
    - - [black_friday]
      - function:bf_code
    - - [gold_tier, eu_region]
      - literal:GOLDEU8
    - - [gold_tier]
      - literal:GOLD5
    - - []
      - literal:WELCOME
```

```ruby
require "trait_engine"

ast    = TraitEngine::Loaders::YamlLoader.load("config/traits/promo.yml")
schema = TraitEngine::Compile::SchemaCompiler.compile(ast)
processor = TraitEngine::Processor.new(schema)

value = processor.resolve_attribute(:promo_code, ctx)
trace = processor.explain(:promo_code, ctx)
```

---

## Under the hood

TraitEngine is organized into four layers:

1. **Parse** (`TraitEngine::Parse`)
   Tokenize and classify your DSL/YAML strings into lightweight *descriptors*.

2. **Syntax** (`TraitEngine::Syntax`)
   Build a location-rich AST of `TraitNode`, `FunctionNode`, `AttributeNode`, `ConditionalCaseNode`.

3. **Compile** (`TraitEngine::Compile::SchemaCompiler`)
   Turn the AST into an immutable `TraitEngine::Runtime::Schema`:

   * **Traits** → `Runtime::Trait` with dependency list and predicate lambda
   * **Functions** → `Runtime::Function` wrappers bundling `SharedFunctions` implementations
   * **Attributes** → `Runtime::Attribute` with either a `Resolver` or a decision‐table

4. **Runtime** (`TraitEngine::Runtime`)

   * **Resolvers** (`Field`, `Literal`, `Function`) implement a uniform interface (`#value`, `#deps`, `#descriptor`).
   * **Processor** executes the DAG in topological order, memoizing and detecting cycles.
   * **Explain** API surfaces matched traits, chosen resolver, and full dependency tree.

Shared, built-in helpers live in `TraitEngine::SharedFunctions` (e.g. `:concatenate`, `:downcase`, `:length`).

---

## Advanced features

* **Cycle detection** prevents infinite loops in your decision graph.
* **Hot-reload** for Rails — change your YAML, hit save, see new behavior without restarting.
* **Plugin-ready**—multi-tenant schemas, custom loaders (JSON, Ruby DSL), and per-schema function overrides.
* **Extensible**—add new resolver types (e.g. `ApiResolver`, `TimeResolver`) by subclassing `Runtime::Resolvers::ResolverBase`.

---

## Contributing & Roadmap

1. Fork the repo & run `bundle install && bundle exec rspec`.
2. Add feature branches under `parse/`, `syntax/`, `compile/`, or `runtime/` as needed.
3. Submit PRs against `main`; we review for tests, docs, and performance.

Planned milestones:

* ⏱️ Benchmark suite & caching strategies
* 🔰 Sorbet / RBS signatures for DSL and runtime APIs
* 🌐 Visual graph inspector (Web UI)

---

## License

MIT © 2025 André Muta

```
```
