---
name: derive-business-rule
description: Extract explicit and derived business rules, constraints, policies, permissions, validations, and lifecycle requirements from the business requirements.
compatibility: opencode
---

# Business Rules Extraction Skill

## Objective

Identify and document all business rules governing the domain, including:

* Explicit rules stated in the requirements
* Derived constraints inferred from entities, attributes, relationships, and lifecycle behavior
* Validation rules
* Permission rules
* State transition constraints
* Temporal constraints
* Relationship participation constraints

The goal is to produce a complete business rule artifact that can support later conceptual design, logical design, validation, and implementation activities.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`
* `docs/business-analysis/derive-entity-att.md`
* `docs/business-analysis/derive-relationship.md`

If an existing analysis already exists, also read:

* `docs/business-analysis/derive-business-rule.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `docs/business-analysis/derive-entity-att.md`
* `docs/business-analysis/derive-relationship.md`

If the file is missing:

* Stop execution.
* Report the missing prerequisite artifact.

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that prerequisite artifacts exist.
2. Read the business requirements.
3. Read the approved entities and attributes.
4. Read the approved relationships.
5. Identify explicit business rules.
6. Analyze entities, attributes, and relationships to derive additional business constraints.
7. Consolidate all discovered business rules.
8. Remove duplicates and implementation-specific rules.

---

## Business Rule Design Rules

### Rule 1 — Explicit Rule Preservation

Business rules explicitly stated in the requirements must be preserved exactly as specified.

Do not weaken, strengthen, or reinterpret explicit rules.

---

### Rule 2 — Derived Rule Traceability

Every derived business rule must be traceable to one of the following:

* Entity attributes
* Relationships
* Relationship attributes
* Lifecycle states
* Temporal dependencies
* Real-world consistency constraints

Do not invent unsupported business policies.

---

### Rule 3 — Business-Level Focus

Business rules must describe business behavior rather than database implementation.

Do not generate:

* Primary key rules
* Foreign key rules
* SQL constraints
* Trigger logic
* Physical database decisions

---

### Rule 4 — Deduplication

If the same constraint can be inferred from multiple sources:

* Keep a single business rule.
* Remove duplicates.
* Prefer the clearest business-oriented wording.

---

## Execution Process

Perform the following steps in order.

Perform the following steps in order.

### Step 1 — Extract Explicit Business Rules

Review the business requirements.

Identify all business rules that are explicitly stated.

Examples include:

* Permission rules
* Approval requirements
* Booking restrictions
* Maintenance restrictions
* Lifecycle requirements
* Validation requirements

Do not derive additional rules in this step.

---

### Step 2 — Analyze Each Entity

For every approved entity:

1. Identify all entity attributes.
2. Identify all relationships involving the entity.
3. Identify all related entities participating in those relationships.
4. Create a consolidated analysis view containing:

   * Entity attributes
   * Connected relationships
   * Relationship attributes

This analysis becomes the basis for rule derivation.

---

### Step 3 — Derive Temporal Constraints

Analyze attributes representing:

* Date
* Time
* Lifecycle events

Determine whether ordering constraints exist.

Examples:

* Start time must occur before end time.
* Approval time cannot precede booking creation.
* Completion time cannot precede maintenance start time.
* Check-in time cannot precede booking approval.

Only derive constraints supported by business meaning.

---

### Step 4 — Derive State-Based Constraints

For every status attribute:

1. Identify all possible status values.
2. Analyze requirements associated with each status.
3. Determine whether certain attributes become:

   * Required
   * Optional
   * Prohibited
4. Determine whether other attributes restrict valid status values.

Examples:

* Rejected booking requires rejection reason.
* Approved booking requires approval information.
* Completed booking requires actual end time.

---

### Step 5 — Derive Enumeration-Based Constraints

For every enumeration attribute:

1. Enumerate all possible values.
2. Analyze whether each value introduces constraints on:

   * Other attributes
   * Related entities
   * Relationship participation

Examples:

* Space status = Retired prohibits new bookings.
* User role = Facility Manager may approve bookings.

Only derive constraints supported by requirements or business meaning.

---

### Step 6 — Derive Real-World Consistency Constraints

Analyze attributes describing the same real-world object, event, or activity.

Identify consistency constraints between them.

Examples:

* Expected participants should not exceed space capacity.
* Actual end time should not precede actual start time.
* Completion time should not exist before start time.

Avoid duplicating constraints already identified in previous steps.

---

### Step 7 — Derive Relationship Constraints

For every relationship:

Analyze constraints between participating entity instances.

Consider:

* Participation restrictions
* Dependency constraints
* Exclusivity constraints
* Coexistence restrictions
* Multiplicity-related business constraints

Examples:

* A space cannot participate in overlapping approved bookings.
* A booking must reference exactly one requester.
* A maintenance record must relate to exactly one space.

Focus on business semantics rather than ERD notation.

---

### Step 8 — Consolidate and Remove Duplicates

Review all identified rules.

Merge rules expressing the same business constraint.

Remove:

* Duplicate rules
* Attribute definitions disguised as rules
* Purely structural ERD information
* Database implementation constraints

Retain only meaningful business constraints.

---

## Important rules

### Scope Restrictions Rules

This stage is responsible only for:

* Extracting explicit business rules
* Deriving logical business constraints
* Deriving lifecycle rules
* Deriving temporal constraints
* Deriving validation rules
* Deriving permission rules
* Deriving participation constraints

This stage is not responsible for:

* Primary key definition
* Foreign key definition
* Normalization
* Logical schema design
* Physical database design
* SQL implementation
* Trigger design
* Database optimization

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

But they are to be seriously considered, since they can be very useful.

---

## Output Specification

Create or update:

`docs/business-analysis/derive-business-rule.md`

The document must follow the template:

`.opencode/skills/business-analysis/derive-business-rule-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

* All explicit business rules are captured.
* Every entity has been analyzed.
* Every relationship has been analyzed.
* Temporal constraints have been evaluated.
* Status attributes have been evaluated.
* Enumeration attributes have been evaluated.
* Relationship constraints have been evaluated.
* Real-world consistency constraints have been evaluated.
* Duplicate rules have been removed.
* No implementation-specific rules are included.
* Every derived rule can be traced back to the business model.

---

## Error Handling

If `docs/business-analysis/derive-entity-att.md` and `docs/business-analysis/derive-relationship.md` do not exist:

- Stop execution.
- Report the missing prerequisite artifact.