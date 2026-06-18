---
name: derive-entity-att
description: Derive candidate entities and attributes from classified concepts by identifying information that requires independent storage, identification, and lifecycle management.
compatibility: opencode
---

# Entity & Attributes Identification Skill

## Objective

Identify candidate business entities and their attributes from the business requirements.

The purpose of this stage is to discover the core business objects and business records that the organization needs to manage, store, reference, and track over time.

The output should reflect the business view of the domain rather than implementation-oriented database structures.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`

If an existing analysis already exists, also read:

* `docs/business-analysis/derive-entity-att.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that `req/business-requirement.md` exists.
2. Read the requirement document completely before performing analysis.
3. Identify all business objectives, users, activities, constraints, and data requirements.
4. If an existing analysis document exists, use it only as reference and regenerate the analysis from the business requirements.
5. Do not assume missing requirements unless necessary.

---

## Entity Design Rules

### 1. Entity Separation Principle

Create a separate entity only if it represents an **independent business process** with its own purpose and meaning in the system.

---

### 2. Actor-Based Separation

If a process is performed by **different user roles independently**, it should be modeled as a separate entity.

* Example:

  * Booking → created by requester
  * Approval → performed by staff/manager
  * Session → handled by facility staff

---

### 3. Lifecycle Independence Rule

An entity should be created if it has its **own lifecycle**, meaning it can:

* be created at a different time

* progress through its own states

* exist even if another related entity does not complete

* Example:

  * A booking can exist without approval
  * A session may not exist for every booking

---

### 4. Data Responsibility Rule

If a set of attributes describes a **different type of information or responsibility**, it should belong to a separate entity.

* Example:

  * Booking → request details
  * Approval → decision details
  * Session → actual usage details

---

### 5. Dependency Rule

Do not separate entities if one cannot exist without the other.

* Example:

  * Check-out cannot exist without check-in
    → therefore both belong to the same Session entity

---

### 6. Avoid Timestamp-Only Entities

Do not create entities whose primary purpose is to store:

* timestamps
* status updates
* simple event markers

These should be attributes of an existing entity.

---

### 7. Independent Lifecycle Rule

A concept is likely an entity if it has its own lifecycle or state transitions.

Examples:

* Sessions have a lifecycle distinct from Booking (scheduled booking may never produce a Session; Sessions may be created or modified by facility staff later).
* Approvals can be created, modified, or revoked independently of the Booking (not just a single timestamp/flag).

Lifecycle states themselves are not entities.

The business record that owns the lifecycle is the entity.

---

### 8. Extensibility Rule

Design entities with consideration for future system changes and feature expansion.

An entity should be structured in a way that allows the system to:

* accommodate new requirements without major redesign
* avoid breaking existing relationships
* minimize schema changes when adding new features

---

### 9. Faithfulness Principle (**Important**)

Entity sets and their attributes should closely reflect **real-world concepts and processes**.

Ideally, each entity represents **a single coherent concept** with:

* a clear purpose
* a consistent set of responsibilities
* and a well-defined role in the system

When an entity appears to combine multiple aspects, consider:

* Does it represent **more than one stage of a real-world process**?
* Are its attributes managed or updated by **different user roles**?
* Do its data elements describe **different types of information** (e.g., request, decision, execution)?

If multiple answers are **yes**, the design may not accurately reflect reality and should be reconsidered.

In such cases, it is often more appropriate to separate the entity into smaller ones, where each:

* represents a distinct real-world process
* is associated with a clearer responsibility
* aligns with a more specific actor or role

---

#### Note on Granularity

However, not all internal steps require separation.
Actions that are:

* tightly coupled
* handled within the same process
* and not independently managed

are often better represented as **attributes rather than separate entities**.

---

## Execution Process

Perform the following steps in order.

## Execution Process

### Step 1 — Review Requirements

Read the complete business requirement document.

Identify:

* Business goals
* Actors
* Business objects
* Business records
* Activities
* Constraints
* Information being stored

---

### Step 2 — Extract Candidate Concepts

Identify all significant concepts mentioned in the requirements.

Include:

* Physical objects
* Organizational objects
* Business records
* Workflow concepts
* Classification concepts

Do not classify yet.

---

### Step 3 — Evaluate Entity Candidates

Apply the Entity Design Rules.

For each concept determine:

* Is it an independent business object?
* Is it a business record?
* Does it have its own lifecycle?
* Does it require independent storage?

If not, exclude it from the entity list.

---

### Step 4 — Collapse Workflow Fragments

Review all workflow-related concepts.

Merge concepts that belong to the same business process.

Examples:

Merge:

* Check In
* Completion

into:

* Booking

when they are merely lifecycle events.

---

### Step 5 — Derive Attributes

For each accepted entity:

* Identify descriptive information
* Remove relationship information
* Remove status value lists
* Remove classifications

Retain only true attributes.

---

### Step 6 — Validate Results

Verify each entity satisfies at least one condition:

* Requires independent storage
* Has business significance
* Has history
* Has lifecycle
* Can be referenced independently

If none apply, remove the entity.

---

## Important rules

### Scope Restrictions Rules

This stage is responsible only for:

* Identifying candidate entities
* Identifying candidate attributes
* Determining why each entity exists in the business domain
* Determining why each attribute belongs to an entity

This stage is NOT responsible for:

* Relationship identification
* Cardinality analysis
* Participation constraints
* ERD construction
* Relational schema design
* Primary key selection
* Foreign key selection
* Normalization
* Supertype/subtype modeling
* Associative entity creation
* Database implementation decisions

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

But they are to be seriously considered, since they can be very useful.

---

## Output Specification

Create or update:

`docs/business-analysis/derive-entity-att.md`

The document must follow the template:

`.opencode/skills/business-analysis/derive-entity-att/derive-entity-att-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

### Entity Validation

* Every entity has independent business meaning.
* Every entity is supported by the requirements.
* No entity exists solely because it is a workflow step.
* No entity exists solely because it is a relationship.
* No entity exists solely because it is an implementation artifact.

### Workflow Validation

* Check-in and completion are not automatically treated as entities.
* Status transitions are not treated as entities.
* Workflow stages are not treated as entities.

### Attribute Validation

* Attributes describe entities.
* Relationship candidates are not stored as attributes.
* Enumeration values are not treated as entities.

### Traceability Validation

* Every entity can be traced to requirement evidence.
* Every attribute can be traced to requirement evidence.

---

## Error Handling

If `req/business-requirement.md` does not exist:

* Stop execution.
* Report the missing file.
* Do not fabricate requirements.

If the requirement document is incomplete:

* Continue analysis using reasonable assumptions.
* Clearly document all assumptions and unresolved questions.

If contradictions are found:

* Record the conflict.
* Explain alternative interpretations.
* Select the most reasonable interpretation and justify it.