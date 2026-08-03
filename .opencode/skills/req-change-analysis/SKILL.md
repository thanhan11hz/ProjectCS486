---
name: req-change-analysis
description: Analyze business requirement changes by identifying affected entities, relationships, business rules, and potential concurrency conflicts.
compatibility: opencode
---

# Requirement Change Analysis Skill

## Objective

* Compare the Phase 1 and Phase 2 business requirements to identify all requirement changes.

* Identify affected entities, attributes, relationships, and business rules.

* Analyze the impact of the requirement changes on the existing database design.

* Identify potential concurrency conflicts introduced by the new requirements.

* Document the required design changes needed to support the updated requirements.

* Produce a structured requirement change analysis that serves as the foundation for updating the ERD, logical schema, schema migration, and concurrency design.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`
* `req/business-requirement-change.md`
* `outputs/01-business-req-analysis-G7.md`

If an existing analysis already exists, also read:

* `outputs/08-req-change-analysis-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `req/business-requirement.md`
* `req/business-requirement-change.md`
* `outputs/01-business-req-analysis-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the original business requirements.
2. Read the updated business requirements.
3. Read the existing business requirement analysis.
4. Compare the original and updated requirements.
5. Identify all requirement changes.
6. Classify requirement changes.
7. Determine affected business elements.
8. Analyze business-level concurrency conflicts introduced by the requirement changes.
9. Generate the requirement change analysis documentation.

---

# Requirement Change Analysis Rules

## Requirement Change Classification Rules

### Rule RC1 — New Requirement

A requirement is classified as a New Requirement when:

* It introduces new business functionality.
* It was not present in the original business requirements.

---

### Rule RC2 — Modified Requirement

A requirement is classified as Modified when:

* It changes the behavior of an existing business requirement.
* It extends or restricts an existing requirement without replacing it entirely.

---

### Rule RC3 — Removed Requirement

A requirement is classified as Removed when:

* It exists in the original requirements.
* It is explicitly removed or replaced by the updated requirements.

---

### Rule RC4 — Clarified Requirement

A requirement is classified as Clarified when:

* It improves the wording of an existing requirement.
* It does not change the underlying business behavior.

---

## Business Element Identification Rules

### Rule B1 — Affected Entity

An entity is affected when:

* Its responsibilities or semantics change.
* It participates in a changed business process.
* A requirement explicitly references changes related to it.

---

### Rule B2 — Affected Attribute

An affected attribute shall be identified only when:

- The updated requirements explicitly introduce the attribute; or
- The updated requirements explicitly modify an existing attribute.

Do not derive new attributes from anticipated database implementation.

If a business concept may be implemented in multiple ways, record the business concept instead of proposing an attribute.

---

### Rule B3 — Affected Relationship

Identify a relationship only when the updated requirements explicitly introduce, remove, or modify a business association between two business entities.

Do not infer relationships solely because two entities interact during a business process.

Do not introduce many-to-many relationships based on anticipated implementation.

---

### Rule B4 — Affected Business Rule

A business rule is affected when:

* It is added.
* It is modified.
* It is removed.
* It is superseded by another business rule.

---

## Concurrency Analysis Rules

Analyze only business-level concurrency conflicts introduced by the updated requirements.

Determine:

* Concurrent operations that may interact.
* Shared business resources involved.
* Possible business rule violations.
* Required business invariants.

Do not propose implementation mechanisms such as locking, transactions, isolation levels, triggers, indexes, or stored procedures.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Load Input Artifacts

Read:

* `req/business-requirement.md`
* `req/business-requirement-change.md`
* `outputs/01-business-req-analysis-G7.md`

Treat the Phase 1 Business Requirement Analysis as the baseline.

---

### Step 2 — Identify Requirement Changes

Compare the original and updated requirements.

Determine:

* New requirements
* Modified requirements
* Removed requirements
* Clarified requirements

Record the source of every identified change.

---

### Step 3 — Identify Affected Business Elements

Determine:

* Affected business processes
* Affected entities
* Affected attributes
* Affected relationships
* Affected business rules

Only identify business elements directly supported by the updated requirements.

---

### Step 4 — Analyze Concurrency Conflicts

Identify possible business-level conflicts introduced by concurrent operations.

For each conflict determine:

* Concurrent operations
* Shared business resources
* Violated business rules
* Business invariant that must be preserved

Do not propose implementation solutions.

---

### Step 5 — Validate Analysis Consistency

Verify that:

* Every requirement change is supported by the updated requirements.
* Every affected business element is traceable to one or more requirement changes.
* No implementation decisions have been introduced.
* Assumptions and open questions are clearly separated from confirmed findings.

---

### Step 6 — Generate Requirement Change Analysis

Produce the document following the required template.

Record:

* Requirement changes
* Affected business elements
* Business rule changes
* Concurrency conflict analysis
* Assumptions
* Open questions

---

## Important rules

### Scope Restriction Rules

This stage is responsible only for business requirement analysis.

Do not:

* Design the ERD.
* Design the relational schema.
* Select entities or attributes based on implementation preferences.
* Propose database tables or columns.
* Discuss migration strategies.
* Recommend SQL implementation techniques.

Those activities belong to later stages.

---

### Traceability Rule

Every identified change must be traceable to one or more updated business requirements.

Every affected business element must reference the requirement changes that affect it.

---

### Modeling Consistency Rule

The original Business Requirement Analysis remains the authoritative baseline.

This stage identifies changes only.

It must not redesign or reinterpret the business model unless the updated requirements explicitly require it.

### Requirement Evidence Rule

Every identified business change must be classified as one of:

- Explicitly Required
- Directly Inferred
- Assumption

Explicitly Required
- Clearly stated in the updated requirements.

Directly Inferred
- Necessitated by the stated business behavior.
- There is no reasonable alternative interpretation.

Assumption
- Introduced to complete the analysis where the requirements are insufficient.

Assumptions must never be presented as confirmed requirement changes.

### Design Independence Rule

Requirement Change Analysis shall identify business changes only.

Do not infer implementation-specific artifacts, including but not limited to:

- Database tables
- Junction tables
- Foreign keys
- Columns
- Timestamps
- Audit attributes
- Boolean flags
- History entities
- Versioning attributes

unless they are explicitly required by the business requirements.

---

## Output Specification

Create or update:

`outputs/08-req-change-analysis-G7.md`

The document must follow the template:

`.opencode/skills/req-change-analysis/req-change-analysis-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving:

* Every requirement change is classified.
* Every requirement change is traceable to the updated requirements.
* Every affected business element is supported by the requirements.
* No implementation-specific entities or attributes have been introduced.
* Every identified entity, attribute, and relationship is supported by explicit requirement evidence.
* No implementation-specific modeling decisions are introduced.
* Business concepts are not prematurely converted into database structures.
* No ERD or relational design decisions are included.
* No SQL implementation details are included.
* All business rule changes are documented.
* All business-level concurrency conflicts introduced by the updated requirements are identified.
* Assumptions are clearly separated from confirmed requirements.
* Open questions are clearly identified.
* The output follows the required template.

---

## Error Handling

If `req/business-requirement.md`, `req/business-requirement-change.md` and `outputs/01-business-req-analysis-G7.md` do not exist:

* Stop execution.
* Report the missing file.