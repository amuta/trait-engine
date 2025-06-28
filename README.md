# TraitEngine  <!-- badges -->
[![Gem Version](https://badge.fury.io/rb/trait_engine.svg)](https://rubygems.org/gems/trait_engine)
[![CI](https://github.com/your-org/trait_engine/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/trait_engine/actions)

*Declarative **trait-driven attribute mapping** for Ruby.*

> Drop 200 lines of `if / case` forests.  
> Model business rules in a **5-primitive DSL**.  
> Ask *why* a value was chosen—get a JSON trace.

---

## 1  Why TraitEngine?

| Pain in typical apps | TraitEngine cure |
|----------------------|------------------|
| Nested conditionals spread across service objects. | One trait table – read and diff like config. |
| Hard-coded branching explodes when tiers or regions grow. | Add a **trait** once, re-use in many attributes. |
| Debugging “why did I get X?” is print-statement archaeology. | `processor.explain(...)` gives a full decision trace. |
| Changing rules needs a code deploy. | Edit DSL or YAML, hot-reload (optional Railtie). |

---

## 2  Quick start

```bash
gem install trait_engine            # or add to Gemfile
```


```ruby
require "trait_engine"

schema = TraitEngine::DSL.build do
  # ------ traits (boolean predicates) ------
  trait_definitions do
    gold_tier     :tier,   'gold'
    eu_region     :region, 'EU'
    high_value    :order_total_cents, :greater_than, 10_000
    black_friday  :season, 'black_friday'
  end

  # ------ functions (pure functions) ------
  function_definitions do
    bf_code :concatenate, literal('BF-'), attribute(:order_id)
  end

  # ------ attributes (values, maybe conditional) ------
  attribute_definitions do
    tier              from_column: :tier
    region            from_column: :region
    order_total_cents from_column: :total_cents
    order_id          from_column: :id
    season            from_identifier: :campaign

    promo_code do
      on_trait  :black_friday,            use_function: :bf_code
      on_traits :gold_tier, :eu_region,   use_literal: 'GOLDEU8'
      on_trait  :gold_tier,               use_literal: 'GOLD5'
      default                             use_literal: 'WELCOME'
    end
  end
end

ctx = { tier: "gold", region: "EU", total_cents: 13_500,
        id: 421, campaign: "summer_sale" }

processor = TraitEngine::Processor.new(schema)
puts processor.resolve_attribute(:promo_code, ctx)
# => "GOLDEU8"

puts processor.explain(:promo_code, ctx).to_pretty_json
# {
#   "matched_traits": ["gold_tier", "eu_region", "high_value"],
#   "picked_resolver":  "literal:GOLDEU8",
#   "depends_on":     [":tier", ":region", ":order_total_cents"]
# }
