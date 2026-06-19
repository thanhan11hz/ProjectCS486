---
name: logical-design
description: Transform the conceptual ERD into a relational schema suitable for database implementation
compatibility: opencode
---

# Logical Database Design Skill

## Objective

Use this skill to transform the conceptual ERD into a relational database schema.

The logical design must identify:

* Relations
* Attributes
* Primary Keys
* Candidate Keys
* Foreign Keys
* Relationship mappings
* Associative relations
* Integrity constraints

The output will be used as input for database implementation.

---

## Required Input Files

Read the following files:

* `outputs/01-business-req-analysis-G7.md`
* `outputs/02-erd-design-G7.md`

If an existing analysis already exists, also read:

* `outputs/03-logical-design-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/01-business-req-analysis-G7.md`
* `outputs/02-erd-design-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the conceptual ERD.
2. Identify entities and their attributes.
3. Identify entity identifiers and candidate keys.
4. Identify relationships and cardinalities.
5. Identify participation constraints.
6. Identify relationship attributes.
7. Identify multivalued, composite, weak, recursive, and specialization constructs.
8. Determine the required relational mappings.

---

## Mapping Rules

Apply the following rules when converting the conceptual ERD into a relational schema.

### Rule 1 — Strong Entity Mapping

For each strong entity:

* Create one relation.
* Include all simple attributes.
* Decompose composite attributes into simple components.
* Select the entity identifier as the primary key.
* Preserve alternative identifiers as candidate keys.

---

### Rule 2 — Weak Entity Mapping

For each weak entity:

* Create one relation.
* Include all simple attributes.
* Include the primary key of the owner entity as a foreign key.
* Primary key = Owner Primary Key + Partial Key.

---

### Rule 3 — Binary 1:1 Relationship Mapping

For each binary 1:1 relationship:

Preferred approach:

* Place a foreign key in the relation with total participation.
* Include relationship attributes in that relation.

Alternative approaches may be used only when clearly justified:

* Merge participating entities.
* Create a separate relationship relation.

Record the rationale for the selected approach.

---

### Rule 4 — Binary 1:N Relationship Mapping

For each binary 1:N relationship:

* Place the primary key of the 1-side entity into the N-side relation as a foreign key.
* Include relationship attributes in the N-side relation.

No additional relation should be created unless justified.

---

### Rule 5 — Binary M:N Relationship Mapping

For each binary M:N relationship:

* Create an associative relation.
* Include foreign keys from both participating relations.
* Primary key = Combination of participating foreign keys.
* Include relationship attributes.

---

### Rule 6 — N-ary Relationship Mapping

For each relationship involving more than two participating entities:

* Create a separate relationship relation.
* Include foreign keys referencing all participating relations.
* Include all relationship attributes.
* Determine the primary key based on relationship cardinality constraints.

Document any assumptions made.

---

### Rule 7 — Multivalued Attribute Mapping

For each multivalued attribute:

* Create a separate relation.
* Include:

  * Owner primary key as a foreign key.
  * Multivalued attribute.
* Primary key = Owner Primary Key + Attribute Value.

---

### Rule 8 — Composite Attribute Mapping

For each composite attribute:

* Replace the composite attribute with its simple component attributes.
* Do not retain the composite attribute itself.

---

### Rule 9 — Relationship Attribute Mapping

For relationships containing attributes:

* Store relationship attributes in the relation representing that relationship.
* For 1:1 and 1:N relationships, place them in the selected target relation.
* For M:N and N-ary relationships, place them in the associative relation.

---

### Rule 10 — Recursive Relationship Mapping

For recursive relationships:

#### Recursive 1:N

* Add a self-referencing foreign key.

#### Recursive M:N

* Create an associative relation containing multiple references to the same relation.

Clearly identify role names when required.

---

### Rule 11 — Candidate Key Preservation

For every relation:

* Preserve all business-defined candidate keys identified during earlier analysis.
* Do not introduce artificial candidate keys without justification.

---

### Rule 12 — Foreign Key Representation

For every mapped relationship:

Document:

* Referencing relation
* Referencing attribute(s)
* Referenced relation
* Referenced primary key

Ensure all conceptual relationships remain represented in the relational schema.

---

### Rule 13 — Derived Attributes

Derived attributes should not be stored unless explicitly required by the business requirements.

If retained:

* Document the rationale.

---

### Rule 14 — Specialization / Generalization Mapping

If subtypes exist:

Select the simplest valid mapping strategy:

* Supertype relation + subtype relations
* Single relation inheritance
* Subtype-only relations

Document the chosen strategy and rationale.

---

## Execution process

Perform the following steps in order.

### Step 1 — Extract Conceptual Design Elements

Review the conceptual ERD and extract:

* Entities
* Attributes
* Identifiers
* Candidate keys
* Relationships
* Cardinalities
* Participation constraints
* Relationship attributes

Create a complete mapping inventory before any transformation begins.

---

### Step 2 — Map Entity Types

For each entity:

* Determine whether it is strong or weak.
* Apply the appropriate entity mapping rule.
* Create the corresponding relation.
* Define primary key.
* Record candidate keys.

Ensure every conceptual entity is represented.

---

### Step 3 — Map Relationship Types

Process each relationship individually.

For every relationship:

* Identify relationship type.
* Determine cardinality.
* Determine participation constraints.
* Determine whether relationship attributes exist.
* Apply the appropriate mapping rule.
* Record the selected mapping strategy.

Ensure every conceptual relationship is represented.

---

### Step 4 — Create Associative Relations

For each relationship requiring its own relation:

* Create the associative relation.
* Add participating foreign keys.
* Define primary key.
* Add relationship attributes.

Verify that the relation correctly preserves relationship semantics.

---

### Step 5 — Resolve Special Constructs

Evaluate all special ER constructs:

* Composite attributes
* Multivalued attributes
* Weak entities
* Recursive relationships
* N-ary relationships
* Subtypes and supertypes
* Derived attributes

Apply the corresponding mapping rules.

Document any assumptions or design decisions.

---

### Step 6 — Define Foreign Keys

For every relation:

* Identify foreign keys.
* Identify referenced relations.
* Verify that all conceptual relationships are represented through foreign key references or associative relations.

Ensure referential integrity can be enforced.

---

### Step 7 — Define Candidate Keys

For every relation:

* Identify business-defined candidate keys.
* Verify consistency with conceptual identifiers.
* Ensure candidate keys remain unique within the relation.

---

### Step 8 — Identify Integrity Constraints

Identify logical constraints implied by the conceptual model:

* Primary key constraints
* Candidate key constraints
* Referential integrity constraints
* Mandatory participation constraints that can be represented logically

Do not introduce implementation-specific constraints.

Do not write SQL.

---

### Step 9 — Generate Relational Schema Diagram

Create a relational schema diagram based on the completed logical schema.

The diagram must:

* Show all relations.
* Show primary keys.
* Show foreign keys.
* Show associative relations.
* Show references between relations.
* Exclude implementation-specific details.

Use Mermaid ER diagram notation.

The diagram is intended for logical schema validation and traceability.

Verify that every foreign key relationship appearing in the schema is represented in the diagram.

---

### Step 10 — Assemble the Relational Schema

Construct the final relational schema.

For every relation document:

* Relation name
* Attributes
* Primary Key
* Candidate Keys
* Foreign Keys

Use a consistent schema notation throughout the document.

---

### Step 11 — Verify Mapping Completeness

Validate the completed logical design.

Confirm that:

* Every entity has been mapped.
* Every attribute has been mapped.
* Every identifier has been preserved.
* Every relationship has been represented.
* Every cardinality has been represented.
* Every relationship attribute has been represented.
* Every foreign key has been identified.
* Every candidate key has been documented.
* Referential integrity is represented.

Record any assumptions required during mapping.

---

## Output Specification

Create or update:

`outputs/03-logical-design-G7.md`

The document must follow the template:

`.opencode/skills/logical-design/logical-design-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving:

* Every conceptual entity becomes a relation.
* Every relation has a primary key.
* Candidate keys are documented.
* Foreign keys are identified.
* Every conceptual relationship is represented.
* 1:1 relationships are mapped correctly.
* 1:N relationships are mapped correctly.
* M:N relationships are resolved through associative relations.
* N-ary relationships are mapped correctly.
* Composite attributes are decomposed.
* Multivalued attributes are resolved.
* Weak entities are mapped correctly.
* Recursive relationships are mapped correctly.
* Relationship attributes are preserved.
* Referential integrity is represented.
* No implementation-specific details are included.
* No SQL syntax appears.
* Logical schema is complete and internally consistent.

---

## Error Handling

If `outputs/01-business-req-analysis-G7.md` and `outputs/02-erd-design-G7.md` do not exist:

* Stop execution.
* Report the missing file.

If cardinalities are ambiguous:

* Document the assumption.
* Justify the mapping decision.

If multiple mappings are possible:

* Select the simplest valid design.
* Record the rationale.

If the conceptual ERD is incomplete:

* Identify the missing information.
* Explain how it affects logical design.
* Continue only when a reasonable mapping can be justified.