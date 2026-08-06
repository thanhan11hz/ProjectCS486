---
name: update-erd-logical
description: Update the ERD and relational schema to incorporate business requirements change while preserving the existing database design.
compatibility: opencode
---

# Update ERD and Logical Schema Skill

## Objective

* Transform the approved requirement changes into an updated conceptual ERD and logical database design.
* Preserve the existing database design whenever possible by applying incremental design changes instead of redesigning the model.
* Determine the appropriate representation of new business concepts as entities, attributes, relationships, or other modeling constructs.
* Update the conceptual and logical models while maintaining consistency with the approved business requirements.
* Identify the functional dependencies of the updated schema.
* Verify that every relation satisfies Third Normal Form (3NF), or document the normalization steps required to achieve 3NF.
* Document all design decisions together with their rationale and traceability.
* Produce the updated ERD and logical schema as the foundation for schema migration.

---

## Required Input Files

Read the following files:

* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`
* `outputs/08-req-change-analysis-G7.md`

If an existing analysis already exists, also read:

* `outputs/09-updated-erd-and-logical-design-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following files must exist:

* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`
* `outputs/08-req-change-analysis-G7.md`

If any prerequisite is missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the approved requirement change analysis.
2. Read the existing conceptual ERD.
3. Read the existing logical design.
4. Identify all approved business changes.
5. Determine the required conceptual model updates.
6. Determine the required logical schema updates.
7. Evaluate alternative design representations when appropriate.
8. Select and justify the preferred design.
9. Validate consistency between the conceptual and logical models.
10. Generate the updated ERD and logical design documentation.
11. Identify functional dependencies for every updated relation.
12. Verify the normal form of each relation.
13. Produce a 3NF verification report.

---

# Design Rules

## Design Preservation Rule

The Phase 1 database design remains the baseline.

Apply the minimum set of design changes necessary to satisfy the updated business requirements.

Avoid redesigning unaffected parts of the model.

---

## Requirement Traceability Rule

Every design change must be traceable to one or more approved requirement changes.

Every modified entity, attribute, relationship, or constraint shall reference the corresponding requirement change.

---

## Design Decision Rule

When multiple valid database representations exist:

* Evaluate the reasonable alternatives.
* Select one design.
* Record the rationale.
* Clearly distinguish design decisions from business requirements.

Do not present design decisions as requirement changes.

---

## Business Concept Transformation Rule

Represent each approved business concept using the most appropriate database modeling construct.

Possible representations include:

* Entity
* Attribute
* Relationship
* Weak Entity
* Associative Entity
* Domain refinement

The selected representation shall be justified.

---

## Incremental Modeling Rule

Prefer extending existing entities and relationships over introducing new modeling elements.

Introduce new entities or relationships only when they provide a clearer conceptual model or are necessary to satisfy the requirements.

---

## Modeling Consistency Rule

The updated conceptual model and logical model shall remain consistent.

Every conceptual element shall have a corresponding logical representation.

---

## Scope Restriction Rules

This stage is responsible for:

* Updating the conceptual ERD.
* Updating the logical schema.
* Making database design decisions.
* Identifying functional dependencies.
* Verifying normal forms up to Third Normal Form (3NF).

Do not:

* Generate migration SQL.
* Implement constraints.
* Design indexes.
* Design concurrency mechanisms.
* Discuss triggers, stored procedures, transactions, or isolation levels.

Those activities belong to later stages.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Load Existing Design

Read:

* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`
* `outputs/08-req-change-analysis-G7.md`

Treat the Phase 1 design as the baseline.

---

### Step 2 — Identify Required Design Changes

Determine which conceptual and logical elements require modification.

Classify each change as:

* Added
* Modified
* Removed
* Unchanged

---

### Step 3 — Evaluate Design Alternatives

For every new business concept:

* Identify feasible database representations.
* Compare the alternatives.
* Select the preferred representation.
* Record the rationale.

---

### Step 4 — Update the Conceptual ERD

Update:

* Entities
* Attributes
* Relationships
* Cardinalities
* Participation Constraints

Preserve unchanged portions of the ERD.

---

### Step 5 — Update the Logical Schema

Update:

* Relations
* Keys
* Foreign Keys
* Domains
* Constraints

Maintain consistency with the conceptual model.

---

### Step 6 — Validate Design Consistency

Verify that:

* Every approved requirement change is represented.
* Every design decision has a documented rationale.
* The conceptual and logical models remain consistent.
* Unaffected components remain unchanged.

---

### Step 7 — Verify Functional Dependencies and Normal Forms

For every relation in the updated logical schema:

* Identify candidate keys.
* Identify all non-trivial functional dependencies.
* Verify First Normal Form (1NF).
* Verify Second Normal Form (2NF).
* Verify Third Normal Form (3NF).

If a relation violates 3NF:

* Explain the violation.
* Describe the normalization steps required.
* Present the normalized relation.

If the schema already satisfies 3NF:

* Provide a concise proof based on the identified functional dependencies.

---

### Step 8 — Generate Updated Design Documentation

Produce the updated ERD and logical schema following the required template.

---

## Output Specification

Create or update:

`outputs/09-updated-erd-and-logical-design-G7.md`

The document must follow the template:

`.opencode/skills/update-erd-logical/update-erd-logical-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving:

* Every approved requirement change is reflected in the updated design.
* Every design change is traceable to the requirement changes.
* Design decisions are clearly distinguished from business requirements.
* Alternative designs are evaluated when appropriate.
* Every design decision includes a rationale.
* The conceptual and logical models remain consistent.
* Unaffected components remain unchanged whenever possible.
* No SQL implementation details are included.
* No migration strategy is discussed.
* The output follows the required template.
* Functional dependencies are identified for every relation.
* Candidate keys are documented.
* Every relation is verified to satisfy 3NF, or the required normalization steps are documented.

---

## Error Handling

If `outputs/02-erd-design-G7.md`, `outputs/03-logical-design-G7.md` and `outputs/08-req-change-analysis-G7.md` do not exist:

* Stop execution.
* Report the missing file.

If conflicting design alternatives exist:

* Evaluate the alternatives.
* Select the most appropriate design.
* Record the rationale.

If a requirement cannot be represented consistently in both the conceptual and logical models:

* Record the issue.
* Document the design decision.
* Continue only when a consistent representation can be established.