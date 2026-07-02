---
name: erd-design
description: Transform business requirement analysis into a conceptual ERD using Chen's notation represented with Mermaid Flowchart
compatibility: opencode
---

# Conceptual ERD Design Skill

## Objective

Use this skill to transform the business requirement analysis into a conceptual Entity Relationship Diagram (ERD).

The conceptual ERD must represent:

* Entities
* Attributes
* Relationships
* Cardinalities
* Participation constraints

Additionally, the conceptual model must classify:

* Strong and Weak Entities
* Identifying and Non-identifying Relationships
* Attribute Types

The output will be used as input for logical database design.

---

## Required Input Files

Read the following files:

* `outputs/01-business-req-analysis-G7.md`

If an existing analysis already exists, also read:

* `outputs/02-erd-design-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/01-business-req-analysis-G7.md`

If the file is missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the Business Requirement Analysis completely.
2. Extract the approved conceptual model.
3. Validate entity, attribute, and relationship consistency.
4. Classify entities.
5. Classify attributes.
6. Classify relationships.
7. Determine cardinalities.
8. Determine participation constraints.
9. Generate conceptual ERD documentation.
10. Generate Chen-style ERD diagram.

---

# Conceptual Modeling Rules

## Entity Classification Rules

### Rule E1 — Strong Entity

An entity is a Strong Entity when:

* It possesses its own identity.
* It can be uniquely identified independently.
* Its existence does not depend on another entity.

Examples:

```text
User
Space
Booking
Maintenance Record
```

---

### Rule E2 — Weak Entity

An entity is a Weak Entity when:

* It cannot be uniquely identified without another entity.
* Its existence depends on an owner entity.
* It participates in an identifying relationship.

Examples:

```text
Order Item
Booking Participant
Invoice Line
```

---

## Relationship Classification Rules

### Rule R1 — Identifying Relationship

A relationship is Identifying when:

* It connects a weak entity to its owner entity.
* The owner contributes to the identity of the weak entity.

---

### Rule R2 — Non-identifying Relationship

A relationship is Non-identifying when:

* Both entities possess independent identity.
* The relationship does not contribute to entity identification.

---

## Attribute Classification Rules

### Rule A1 — Key Attribute

An attribute is a Key Attribute when:

* It uniquely identifies an entity occurrence.

Examples:

```text
user_id
space_code
booking_id
```

---

### Rule A2 — Composite Attribute

An attribute is Composite when:

* It can be meaningfully decomposed into subattributes.

Examples:

```text
full_name
address
```

---

### Rule A3 — Multivalued Attribute

An attribute is Multivalued when:

* Multiple values may exist for a single entity occurrence.

Examples:

```text
phone_numbers
skills
facilities
```

---

### Rule A4 — Derived Attribute

An attribute is Derived when:

* Its value can be calculated from other stored data.

Examples:

```text
age
booking_duration
maintenance_duration
```

---

### Rule A5 — Simple Attribute

An attribute is Simple when:

* It is atomic.
* It cannot be meaningfully decomposed.

Examples:

```text
email
capacity
status
```

---

## Cardinality Rules

Use cardinalities defined in the Business Analysis whenever available.

If cardinalities are missing:

* Infer the most reasonable interpretation.
* Record the assumption and justification.

---

## Participation Rules

### Total Participation

The entity must participate in the relationship.

---

### Partial Participation

The entity may exist without participating in the relationship.

---

## Execution process

Perform the following steps in order.

## Step 1 — Load Business Analysis

Read: `outputs/01-business-req-analysis-G7.md`

Extract:

* Accepted Entities
* Entity Attributes
* Relationships
* Cardinalities
* Participation Constraints
* Business Rules
* Assumptions
* Conflict Resolution Decisions

Treat the Business Analysis as the authoritative source.

Do not re-discover entities or relationships unless required information is missing.

---

## Step 2 — Validate Model Consistency

Verify that:

* Every relationship references valid entities.
* Every attribute belongs to a valid entity.
* Cardinalities are defined for major relationships.
* Participation constraints are available when known.
* Modeling decisions are internally consistent.

If inconsistencies are found:

* Record the issue.
* Apply documented conflict-resolution decisions.
* Avoid introducing new modeling elements whenever possible.

---

## Step 3 — Classify Entities

For every accepted entity:

Determine:

* Strong Entity
* Weak Entity

Apply the Entity Classification Rules.

Record:

* Classification
* Justification

---

## Step 4 — Classify Attributes

For every attribute:

Determine whether it is:

* Key Attribute
* Simple Attribute
* Composite Attribute
* Multivalued Attribute
* Derived Attribute

Apply the Attribute Classification Rules.

If the attribute can be meaningfully decomposed, decomposed it into subattributes

Record:

* Classification
* Justification

## Step 5 — Classify Relationships

For every relationship:

Determine whether it is:

* Identifying Relationship
* Non-identifying Relationship

Apply the Relationship Classification Rules.

Record:

* Classification
* Justification

---

## Step 6 — Validate Cardinalities and Participation

Review:

* Relationship cardinalities
* Participation constraints

If information is missing:

* Make a justified assumption.
* Record the assumption.

## Step 7 — Generate Conceptual ERD Description

Produce:

### Entity Classification

### Attribute Classification

### Relationship Classification

### Entity Definitions

### Relationship Definitions

### Cardinality Summary

### Participation Summary

### Assumptions

---

## Step 8 — Generate Conceptual ERD Diagram

Transform the classified conceptual model into a Chen-style ERD.

Represent:

```text
Entity → Rectangle

Weak Entity → Double Rectangle

Attribute → Oval

Multivalued Attribute → Double Oval

Derived Attribute → Dashed Oval

Key Attribute → Underlined attribute name

Decomposite Attribute → Oval links to subattributes

Subattribute (of Decomposite Attribute) → Oval 

Relationship → Diamond

Relationship Attribute → Oval

Identifying Relationship → Double Diamond
```

Do not introduce new entities, attributes, or relationships during diagram generation.

---

## Step 9 — Validate ERD Completeness

Verify that:

* Every accepted entity appears in the ERD.
* Every major attribute appears.
* Every relationship appears.
* Every relationship includes cardinality information.
* Participation constraints are documented.
* Entity classifications are documented.
* Attribute classifications are documented.
* Relationship classifications are documented.
* No primary keys are shown.
* No foreign keys are shown.
* No relational schema concepts are shown.
* Mermaid syntax is valid.
* Mermaid Flowchart notation is used.

Record all assumptions and modeling decisions.

---

## Important rules

### Scope Restrictions Rules

This stage is not responsible for:

* Relational schema design
* Primary key selection
* Foreign key identification
* SQL design
* Table normalization
* Constraint implementation

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

Do not reuse example entities, actors, activities, or business rules from the examples.

Always derive results exclusively from the provided business requirements.

### Modeling Consistency Rule

The Business Analysis remains the authoritative source.

This stage may classify modeling elements but must not substantially alter the approved business model.

---

### Diagram Notation Rule

Use Mermaid Flowchart to simulate Chen notation.

Do not use Mermaid ERD notation.

---

## Output Specification

Create or update:

`outputs/02-erd-design-G7.md`

The document must follow the template:

`.opencode/skills/erd-design/erd-design-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving:

* Every entity from business analysis appears in the ERD.
* Every major attribute is represented.
* Every relationship is represented.
* Every relationship has cardinality.
* Participation constraints are included when known.
* No foreign keys are shown.
* No SQL concepts are shown.
* Mermaid syntax is valid.
* Mermaid Flowchart is used.
* Mermaid ERD is not used.

---

## Error Handling

If `outputs/01-business-req-analysis-G7.md` does not exist:

* Stop execution.
* Report the missing file.

If conflicting entity or relationship definitions are found:

* Record the conflict.
* Select the most reasonable interpretation.
* Document the decision.

If cardinalities cannot be determined confidently:

* Make a justified assumption.
* Record the assumption in the output.