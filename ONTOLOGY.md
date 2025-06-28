Acknowledged. I have consolidated, refined, and edited the entire formalization into a single, canonical Markdown document. I have removed the earlier, less comprehensive examples to keep the text concise and focused on the most robust use case, as requested.

Here is the complete document in Markdown format.

````markdown
# Formalization of the Declarative Composition Graph Pattern

## 1. Abstract

This document provides a formal ontological definition of the **Declarative Composition Graph (DCG)** pattern. The pattern provides a solution to the problem of **State-Dependent Attribute Derivation** by defining a system for the **Contextual Instantiation of an Abstract Logical Schema**. It specifies the fundamental entities (the "things"), their properties, and the relationships (the "edges") that can exist between them.

## 2. The Ontological Framework: Two Worlds

The DCG pattern operates across a fundamental boundary between two distinct worlds:

* **The Abstract Logical Schema:** A pure, stateless, declarative graph of logical relationships. It is a universal template for reasoning, defining *what could be true* and *how values could be derived*. It is the world of potentiality.

* **The Concrete Context:** The stateful, external world containing the actual data for a specific entity (e.g., databases, APIs, caches). This world is opaque to the schema and represents *what is*.

The purpose of the DCG pattern is to provide a safe, introspectable, and declarative interface for executing the abstract schema against the concrete context.

## 3. The Hierarchy of Entities

The universe of the DCG is composed of a hierarchy of entities. The base entity is the **Node**. The primary ontological distinction between nodes is their relationship to the **Concrete Context** and the **purity** of their resolution function.

### 3.1. `Node` (The Base Entity)

* **Essence:** A **Logically Addressable Entity**.
* **Definition:** The most primitive element in the graph. It is a uniquely identifiable "thing" that possesses a value that can be resolved.

### 3.2. First-Order Entities: The Axiomatic vs. Inferential Divide

All nodes belong to one of two fundamental categories.

#### 3.2.1. `Source Node` (The Axiomatic)

* **Essence:** A **Promise of External Data**.
* **Definition:** A node that represents a direct query against the **Concrete Context**. It is the formal gate through which data enters the **Abstract Logical Schema**. It is axiomatic because its value is taken as a given "fact" from the outside world.
* **Formal Properties:**
    * Has an in-degree of zero within the schema. Its only dependency is on the external Context Handle.
    * Its resolution is, by definition, an **impure** operation (I/O).

#### 3.2.2. `Derived Node` (The Inferential)

* **Essence:** A **Declaration of Logical Relationship**.
* **Definition:** A node whose value is computed as a function of its dependencies on other nodes (`Source` or `Derived`). It represents knowledge that is inferred from other knowledge within the schema.
* **Formal Properties:**
    * Has an in-degree greater than zero.
    * Its resolution can be either **pure** or **impure**.

### 3.3. Second-Order Entities: Sub-Types of `Derived Node`

The class of `Derived Node` is further specialized based on its logical function and purity.

#### 3.3.1. `Predicate`

* **Essence:** A **Declaration of Truth**.
* **Parent:** `Derived Node`.
* **Purity:** Typically **Pure**. Its resolution is a deterministic boolean function of its inputs.
* **Function:** To serve as a reusable, named logical condition for use in other derivations.

#### 3.3.2. `Cascade`

* **Essence:** A **Declaration of Deterministic Choice**.
* **Parent:** `Derived Node`.
* **Purity:** **Pure**. Its resolution is a deterministic selection process based on the values of its `Predicate` dependencies.
* **Function:** To select a single, unambiguous outcome from a list of possibilities, representing a complex, mutually exclusive business decision.

#### 3.3.3. `Computation`

* **Essence:** A **Declaration of Transformation**.
* **Parent:** `Derived Node`.
* **Purity:** Can be either **Pure** or **Impure**.
    * A **Pure Computation** applies a deterministic function with no side effects (e.g., string concatenation).
    * An **Impure Computation** applies a function that performs a side effect, typically a dependent I/O operation (e.g., an API call that uses the value of another node as a parameter).
* **Function:** To represent data transformations, combinations, calculations, or dependent external queries.

## 4. The Ontology of Edges (Relationships)

An edge `(u, v)` represents a directed dependency where the resolution of node `v` requires the resolved value of node `u`.

### 4.1. `Hydration Edge`

* **Source:** The **Context Handle** (e.g., `user_id: 123`).
* **Target:** A `Source Node`.
* **Essence:** **Contextual Grounding**.
* **Definition:** This is a special type of edge that crosses the boundary from the **Concrete Context** into the **Abstract Logical Schema**. It represents the action of a `Source Node` using the context handle to perform an I/O operation and hydrate itself with a value.

### 4.2. `Value Edge`

* **Source:** Any `Node` (`u`).
* **Target:** A `Computation` or a rule within a `Cascade` (`v`).
* **Essence:** **Data-Flow**.
* **Definition:** Represents a standard data dependency. The resolved value of `u` is required as a direct input for the computation of `v`.

### 4.3. `Predicate Edge`

* **Source:** A `Predicate` node (`u`).
* **Target:** A rule within a `Cascade` node (`v`).
* **Essence:** **Logical Gating**.
* **Definition:** A specialized dependency where the boolean value of the `Predicate` `u` determines whether a specific rule within the `Cascade` `v` is considered for execution. It does not provide data for computation but rather controls the logical flow of the resolution.

## 5. A Formal Description of the DSL Syntax

The following example uses a Domain-Specific Language (DSL) to define the schema. This DSL provides a structured syntax for declaring the nodes and edges of the graph.

* **`attribute :name, ...`**: Declares a node that produces a value. Ontologically, this can represent a `Source Node`, a `Cascade`, or a `Computation`, depending on how it is defined.
    * `from_field: :key`: Defines a `Source Node`.
    * A block with `on_trait` rules (`do...end`): Defines a `Cascade`.
* **`trait :name, ...`**: Declares a `Predicate` node. It defines a named boolean condition.

* **`function :name, ...`**: Declares a `Computation` node. It defines a named transformation. Its body is always an `fn(...)` call.


## 6. Illustrative Example: Financial Service Loan Pre-Screening

### 6.0 User Story

**As a** loan underwriter  
**I want** to automatically pre-screen incoming loan applications  
**Given** an applicant’s age, employment status, SSN, credit report data, and campaign context  
**So that** I can  
  - immediately reject underage or high-risk applicants,  
  - auto-approve strong candidates,  
  - flag borderline cases for manual review,  
  - compute a numeric risk score for portfolio analytics.  

---

### 6.1 Schema Definition

```ruby
# An example schema for pre-screening a loan application
schema do
  # --- Attributes (Representing Source Nodes and Cascades) ---
  attribute :applicant_age,       from_field: :age
  attribute :employment_status,   from_field: :employment_status
  attribute :applicant_ssn,       from_field: :ssn

  # This attribute's value is derived from a complex, dependent function call
  attribute :credit_report,       use_function: :fetch_credit_report

  # This attribute is a Cascade, representing the final decision
  attribute :application_status do
    on_trait :is_underage,              use_literal: 'auto_rejected_age'
    on_trait :has_recent_bankruptcy,    use_literal: 'auto_rejected_bankruptcy'
    on_trait :has_poor_credit,          use_literal: 'auto_rejected_credit'
    on_traits :has_good_credit,
              :has_stable_employment,   use_literal: 'auto_approved'
    default                             use_literal: 'manual_review'
  end

  # --- Traits (Representing Predicate Nodes) ---
  trait :is_underage,             :applicant_age, :less_than, 18
  trait :has_recent_bankruptcy,   :active_bankruptcies, :greater_than, 0
  trait :has_good_credit,         :credit_score, :greater_than_or_equal, 700
  trait :has_poor_credit,         :credit_score, :less_than, 600
  trait :has_stable_employment,   :employment_status, :in, ['employed', 'self_employed']

  # --- Functions (Representing Computation Nodes) ---
  function :fetch_credit_report,  fn(:fetch_credit_report_api, attribute(:applicant_ssn))

  # These functions parse data out of the complex credit_report attribute
  function :credit_score,        fn(:pluck, attribute(:credit_report), literal('score'))
  function :active_bankruptcies, fn(:pluck, attribute(:credit_report), literal('bankruptcies'))

  function :risk_score,           fn(:calculate_risk, function(:credit_score), attribute(:applicant_age))

  # This is the final composed output, defined as a function for ontological clarity
  function :decision_summary,     fn(:build_hash, {
    status: attribute(:application_status),
    risk_score: function(:risk_score),
    credit_score: function(:credit_score)
  })
end
```

### 6.2. Ontological Mapping

#### Source Nodes (The Axiomatic)

  * `attribute :applicant_age`, `attribute :employment_status`, `attribute :applicant_ssn`: These are simple `Source Nodes` hydrated from the initial application context.

#### Derived Nodes (The Inferential)

  * `function :fetch_credit_report`: This is an **Impure `Computation`**. It depends on the `:applicant_ssn` `Source Node` via a **Value Edge** and performs I/O to an external credit bureau. The `attribute :credit_report` then uses this function, acting as an alias.
  * `function :credit_score`, `function :active_bankruptcies`: These are **Pure `Computations`**. They transform the data fetched by the `:credit_report` node.
  * `trait :is_underage`, `trait :has_good_credit`, etc.: These are **Pure `Predicates`**. They create reusable logical assertions based on the values of other `Source` and `Derived` nodes.
  * `function :risk_score`: A **Pure `Computation`** that calculates a final score.
  * `attribute :application_status`: This is a `Cascade`. Its rules are gated by **Predicate Edges** from various traits to determine the final, deterministic status.
  * `function :decision_summary`: A **Pure `Computation`** that acts as a final assembler. It composes the results of multiple other nodes.

This example demonstrates a deeply nested graph where the final output is composed of multiple, interdependent derivations, including those that rely on impure, dependent I/O calls.

## 7. Mapping the Ontology to the AST

This section maps the abstract ontological entities to the concrete syntax nodes found in the reference implementation. The Abstract Syntax Tree (AST) is the data structure that represents the parsed logic before it is compiled into an executable runtime graph.

### 7.1. `Source Node` → `Attribute` (with Source Descriptor)

In the AST, a `Source Node` does not exist as a standalone node type. It is implicitly defined by an `Attribute` node whose resolution is specified as a direct data fetch.

  * **AST Node:** `TraitEngine::Syntax::Nodes::Attribute`
  * **Semantic Trigger:** When defined with a `from_column:` or `from_identifier:` clause.
  * **Mapping:** The `Attribute` node `tier` defined as `from_field: :tier` is the AST representation of a **Source Node**.

### 7.2. `Predicate` → `Trait`

The ontological `Predicate` maps directly to the `Trait` syntax node.

  * **AST Node:** `TraitEngine::Syntax::Nodes::Trait`
  * **Mapping:** A `Trait` node is the AST representation of a **Predicate**.

### 7.3. `Cascade` → `Attribute` (with `ConditionalCase` children)

The ontological `Cascade` is represented by an `Attribute` node that contains a block of prioritized conditional rules.

  * **AST Node:** `TraitEngine::Syntax::Nodes::Attribute` (as the container)
  * **Child AST Nodes:** `TraitEngine::Syntax::Nodes::ConditionalCase` (representing the `on_trait` / `default` rules).
  * **Mapping:** The `application_status` `Attribute` node is the AST representation of a **Cascade**.

### 7.4. `Computation` → `Function`

The ontological `Computation` maps directly to the `Function` syntax node.

  * **AST Node:** `TraitEngine::Syntax::Nodes::Function`
  * **Mapping:** A `Function` node is the AST representation of a **Computation**.

-----

This formal ontology provides a complete, structured, and hierarchical framework for understanding, discussing, and implementing the **Declarative Composition Graph** pattern.

```