---
name: derive-entity-att
description: Derive candidate entities and attributes from classified concepts by identifying information that requires independent storage, identification, and lifecycle management.
compatibility: opencode
---

# Business Requirement Understanding Skill

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

## Entity Identification Rules

### Rule 1 

A concept should be considered an entity if the organization manages it as an independent business object.

Indicators include:

* Has its own business meaning
* Exists independently of a single transaction
* Must be stored and retrieved later
* Can be referenced by multiple activities

Examples:

* User
* Space
* Facility

---

### Rule 2 

A concept may also be considered an entity when it represents a business record that must be tracked over time.

Indicators include:

* Has a lifecycle
* Has a status
* Maintains historical information
* Requires auditing or reporting

Examples:

* Booking
* Maintenance Record

These are not physical objects but are still valid business entities because they represent business records that must be managed independently.

---

### Rule 3

Information that merely describes another object is not an entity.

Such information should be treated as attributes.

Examples:

* Phone Number
* Email
* Capacity
* Purpose
* Usage Note
* Floor
* Building

---

### Rule 4

Classification values and status values are not entities.

Examples:

* Student
* Lecturer
* Facility Staff
* Available
* Under Maintenance
* Pending
* Approved
* Rejected

These should be treated as attribute values unless the requirements explicitly indicate separate management of those concepts.

---

### Rule 5 

If theses entities represent workflow stages and contain information, don't merge them. Do not create entities for concepts that merely express a connection between two business objects with only connection meaning. 

Examples:

* Space Facility
* User Space
* Space Usage

These should remain relationship candidates for later analysis.

The decision to create associative entities belongs to later design stages.

---

### Rule 6

When determining whether a concept should be merged into another entity or modeled separately, evaluate whether the concept represents business information owned or produced by a different actor.

A concept should not automatically be treated as a workflow step merely because it occurs within the lifecycle of another entity.

Indicators that a concept may deserve separate consideration include:

* The information is created or maintained by a different business role.
* The information records a decision, assessment, approval, verification, inspection, or operational activity performed by another actor.
* The information has its own business meaning independent of the parent entity.
* The information may reasonably be audited, reviewed, or reported separately.

---

## Attribute Identification Rules

### Rule 7

An attribute should describe a property of an entity.

Examples:

User

* user_id
* full_name
* email
* phone_number
* account_status

Space

* space_code
* space_name
* capacity
* room_number

---

### Rule 8 

Do not classify references to other business objects as attributes.

Examples:

Booking references:

* requester
* space
* approver

These indicate relationships and should be handled later.

---

### Rule 9

Attributes should represent a single piece of business information whenever practical.

Avoid deriving large narrative structures or combined concepts as attributes.

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

Apply the Entity Identification Rules.

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

### Step 5 — Evaluate Approval Concepts

Apply the Approval Identification Rules.

Do not create Approval entities unless explicit evidence supports independent approval management.

---

### Step 6 — Derive Attributes

For each accepted entity:

* Identify descriptive information
* Remove relationship information
* Remove status value lists
* Remove classifications

Retain only true attributes.

---

### Step 7 — Validate Results

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

Do not reuse example entities, actors, activities, or business rules from the examples.

Always derive results exclusively from the provided business requirements.

---

## Output Specification

Create or update:

`docs/business-analysis/derive-entity-att.md`

The document must follow the template:

`.opencode/skills/business-analysis/derive-entity-att-template.md`

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

### Approval Validation

* Approval entities exist only when explicitly justified by requirements.

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