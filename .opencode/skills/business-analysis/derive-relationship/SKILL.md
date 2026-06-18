---
name: derive-relationship
description: Identify business relationships between candidate entities, including relationship meaning, participation constraints, and cardinalities.
compatibility: opencode
---

# Relationship Identification Skill

## Objective

Identify business relationships between approved entities derived from the previous analysis stage.

For each relationship:

* Identify the business meaning.
* Determine participation constraints.
* Determine cardinalities.
* Identify relationship attributes when applicable.

The purpose of this stage is to prepare relationship information required for conceptual ERD design.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`
* `docs/business-analysis/derive-entity-att.md`

If an existing analysis already exists, also read:

* `docs/business-analysis/derive-relationship.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `docs/business-analysis/derive-entity-att.md`

If the file is missing:

* Stop execution.
* Report the missing prerequisite artifact.

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that `docs/business-analysis/derive-entity-att.md` exists.
2. Read the business requirements and approved entities.
3. Identify business interactions between approved entities.
4. Determine relationship constraints and attributes.
5. Generate the relationship analysis artifact.

---

## Relationship Design Rules

### Rule 1 — Relationship Must Represent Business Meaning

A relationship must describe a genuine business association between entities.

Examples:

* User submits Booking
* Booking reserves Space
* User reports Maintenance Record

Do not model attributes as relationships.

---

### Rule 2 — Use Verb-Based Relationship Names

Relationship names should describe the business action.

Preferred examples:

* submits
* reserves
* approves
* reports
* assigned_to

Avoid generic names such as:

* has
* contains
* related_to

unless no better business term exists.

---

### Rule 3 — Avoid Derived Relationships

Do not create relationships that can already be inferred through other relationships.

Example:

If:

User → Booking

and

Booking → Space

exist,

do not additionally create:

User → Space

unless the requirements explicitly describe a direct association.

---

### Rule 4 — Preserve Distinct Business Roles

When the same entity pair participates in different business roles, model separate relationships.

Example:

User ↔ Booking

may produce:

* submits
* approves
* checks_in

Each relationship has different business meaning.

---

### Rule 5 — Relationship Attributes Belong to the Association

Create a relationship attribute when its value depends on a specific association between participating entities rather than on either entity individually.

A relationship attribute is appropriate when:

* The value cannot be determined from either entity alone.
* The value varies across different instances of the same relationship.
* The value describes the association itself.

Do not create a relationship attribute if the information naturally belongs to an entity.

---

### Rule 6 — Examine Many-to-Many Relationships Carefully

For every M:N relationship, explicitly evaluate whether the association has its own attributes.

Many-to-many relationships frequently contain business information that depends on the specific entity pair.

Do not assume that an M:N relationship has no attributes.

---

### Rule 7 — Identify Missing Relationship Attributes

When a many-to-many relationship represents allocation, assignment, composition, equipment provision, or resource availability, evaluate whether the requirements imply association-specific information that has not been explicitly specified.

Examples:

* Space equipped_with Facility → quantity
* Supplier supplies Product → unit price
* Student enrolls Course → grade

If such information is strongly implied but not explicitly stated:

* Record it as a candidate relationship attribute.
* Mark it as an assumption or design consideration.
* Do not treat it as a confirmed requirement.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Load Approved Entities

Read:

`docs/business-analysis/derive-entity-att.md`

Extract all approved entities.

Only approved entities may participate in relationships.

Do not introduce new entities.

---

### Step 2 — Review Requirements

Read the complete business requirement document.

Focus on statements that describe:

* Business interactions
* Ownership
* Assignment
* Usage
* Approval
* Reporting
* Management responsibilities

Record the supporting requirement evidence.

---

### Step 3 — Extract Candidate Relationships

Identify interactions between approved entities.

For each candidate relationship:

* Source entity
* Target entity
* Business meaning
* Supporting evidence

Use verb-based names that reflect the business activity.

---

### Step 4 — Validate Candidate Relationships

Verify that each candidate:

* Represents a real business association
* Is supported by the requirements
* Is not an attribute
* Is not a classification
* Is not a derived relationship

Discard invalid candidates.

---

### Step 5 — Determine Cardinalities

For each validated relationship:

Determine:

* Minimum participation
* Maximum participation

Express the resulting cardinality as:

* 1:1
* 1:N
* M:N

Use only information supported by the requirements.

---

### Step 6 — Determine Participation Constraints

For each side of the relationship:

Determine whether participation is:

* Mandatory
* Optional

Provide supporting evidence whenever possible.

---

### Step 7 — Identify Relationship Attributes

For each approved relationship, determine whether any information describes the association itself.

A candidate relationship attribute should satisfy one or more of the following:

* Its value depends on a specific pair of related entities.
* Its value may differ across instances of the same relationship.
* It describes how the entities are connected.

Reject the attribute if it naturally belongs to one participating entity.

Do not duplicate existing entity attributes.

---

### Step 8 — Consolidate Relationships

Merge duplicate relationships that represent the same business meaning.

Keep separate relationships when they represent different business roles.

---

### Step 9 — Produce Relationship Analysis

For each approved relationship record:

* Relationship name
* Participating entities
* Business meaning
* Cardinality
* Participation constraints
* Relationship attributes
* Supporting evidence

Save the result to:

`docs/business-analysis/derive-relationship.md`

---

## Important rules

### Scope Restrictions Rules

This stage is responsible only for:

* Create new entities
* Define primary keys
* Define foreign keys
* Create relational tables
* Normalize data
* Design SQL schemas

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

But they are to be seriously considered, since they can be very useful.

---

## Output Specification

Create or update:

`docs/business-analysis/derive-relationship.md`

The document must follow the template:

`.opencode/skills/business-analysis/derive-relationship/derive-relationship-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

* Every relationship connects approved entities.
* Relationship names are business meaningful.
* Cardinalities are specified.
* Participation constraints are specified.
* Relationship attributes are justified.
* No relationship duplicates another.
* No attribute is incorrectly modeled as a relationship.
* No derived relationship is included without evidence.

---

## Error Handling

If `docs/business-analysis/derive-entity-att.md` does not exist:

- Stop execution.
- Report the missing prerequisite artifact.

If a relationship cannot be justified from the requirements:

- Do not create the relationship.
- Record the uncertainty if necessary.