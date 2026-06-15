---
name: business-analysis
description: Analyze the requirements to identify the business purpose, actors, entities, attributes, relationships, cardinalities, and business rules
compatibility: opencode
-----------------------

# Business Requirements Analysis Skill

## Objective

Use this skill to transform a business requirement document into a structured business analysis document containing:

* Business purpose
* Actors
* Candidate entities
* Attributes
* Relationships
* Cardinalities
* Business rules
* Assumptions and ambiguities

The output of this skill will be used as input for conceptual design and logical design.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`

If an existing analysis already exists, also read:

* `docs/01-business-requirement-analysis.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

This is the first stage of the database design pipeline.

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that `req/business-requirement.md` exists.
2. Read the requirement document completely before performing analysis.
3. Identify all business objectives, users, activities, constraints, and data requirements.
4. If an existing analysis document exists, use it only as reference and regenerate the analysis from the business requirements.
5. Do not assume missing requirements unless necessary.

---

## Methodology

Perform the analysis using the following process:

### 1. Identify Business Purpose

Determine:

* The organization or domain
* The problem being solved
* The purpose of the proposed database system
* Expected business outcomes

### 2. Identify Actors

Identify all parties that interact with the system.

For each actor:

* Name
* Actor type
* Description
* Responsibilities

Actor Type should follow DBMS user classifications where applicable:

* DBA (Database Administrator)
* Database Designer / System Analyst
* Application Developer
* Parametric (Naive) End User
* Casual End User
* Sophisticated End User
* Standalone User
* External System

### 3. Identify Entities

Identify objects that:

* Have independent existence
* Require stored information
* Participate in business activities

For each entity:

* Name
* Description

### 4. Identify Attributes

For each entity:

* Identify candidate attributes
* Identify possible identifiers
* Mark potential primary keys

### 5. Identify Relationships

Identify how entities interact.

Before identifying relationships, determine whether an interaction represents:

* a business association between independent business objects, or
* a step, action, decision, transition, or milestone within a business process.

Only model business associations as relationships.

Do not create separate relationships for actions that occur within the lifecycle of an existing business process unless those actions must be independently managed, tracked, or related to other business objects.

For each relationship:

* Participating entities
* Relationship attributes (if any)
* Relationship degree
* Relationship meaning
* Business interpretation

### 6. Identify Cardinalities

Determine:

* One-to-one
* One-to-many
* Many-to-many

based on business requirements.

### 7. Identify Business Rules

Extract:

* Explicit business rules directly stated in requirements
* Derived business rules inferred from requirements

Assign identifiers:

* BR-01, BR-02, ...
* DR-01, DR-02, ...

### 8. Identify Ambiguities

When requirements are unclear:

* Record the ambiguity
* List possible interpretations
* Select a reasonable assumption
* Provide justification

---

## Design Rules

### Entity Identification Rules

An entity should:

* Have independent business meaning
* Possess a unique identifier
* Participate in at least one relationship

Do not model the following as entities unless explicitly required:

* Status values
* Enumerations
* Categories
* Simple descriptions

Do not model lifecycle stages of the same business process as separate entities unless the stage has independent existence and its own business identifier instead of creating separate entities.

Do not introduce an associative entity merely because a relationship is M:N.

First determine whether the relationship represents:

* a business process,
* a business event,
* a transaction,
* or an independently managed business object.

Create an associative entity only when the relationship:

* has its own business identity,
* has a lifecycle or status,
* participates in additional relationships,
* stores significant business information,
* or must be tracked independently over time.

Otherwise, model it as a relationship, even if the relationship is M:N.

### Attribute Identification Rules

Attributes should:

* Describe characteristics of an entity.
* Be atomic whenever possible.
* Avoid derived values unless required by the business.
* Have clear business meaning.
* Represent information that must be stored rather than inferred from relationships or business rules.

Do not model the following as attributes when they represent independent business concepts:

* Business objects that require their own identity.
* Business processes or transactions.
* Multi-valued information that should be modeled separately.
* Information that belongs to a relationship rather than an entity.

Consider whether an attribute:

* Is mandatory or optional.
* May participate in identification.
* May be constrained by business rules.
* May influence the state or lifecycle of the entity.

### Relationship Rules

Every identified relationship should:

* Connect valid entities.
* Have a clear business meaning.
* Include cardinality.
* Be supported by the business requirements.
* Represent an actual business association rather than a technical implementation detail.

For each relationship, determine:

* Participation constraints.
* Direction of business interaction where applicable.
* Whether the relationship is mandatory or optional.
* Whether the relationship has its own attributes.
* Whether the relationship represents a business event, transaction, or process.

Do not introduce associative entities solely because a relationship exists or because the relationship is many-to-many.

Only introduce an associative entity when the relationship itself has independent business significance and must be managed, tracked, or governed by business rules.

Prefer modeling business associations as relationships before considering implementation-oriented structures.

### Business Rule Rules

Business rules should:

* Be testable.
* Be unambiguous.
* Be traceable to one or more requirement statements.
* Express a business constraint, policy, condition, or obligation.
* Describe what must, must not, can, or cannot occur within the business domain.
* Remain independent of implementation details whenever possible.

A business rule should not merely restate stored data. It should define constraints, permissions, dependencies, or conditions governing the use of that data.

When identifying business rules, analyze the requirements for:

* Validation constraints on data values.
* Constraints involving multiple entities or relationships.
* Temporal or sequencing requirements.
* Authorization and responsibility restrictions.
* State- or status-dependent behavior.
* Preconditions and postconditions of business activities.
* Exclusivity, uniqueness, capacity, or availability constraints.
* Lifecycle and workflow constraints.
* Historical record retention requirements.
* Mandatory versus optional business actions.

Classify identified business rules where appropriate into categories such as:

* Data Validation Rules
* Relationship Rules
* Temporal Rules
* Authorization Rules
* Status Rules
* Lifecycle Rules
* Cross-Entity Rules
* Operational Policies

If a business rule is implied by multiple requirement statements but not explicitly stated, record it as a derived business rule and document the reasoning used to infer it.

Do not infer business rules that cannot be reasonably justified from the requirements.

---

## Output Specification

Create or update:

`docs/01-business-requirement-analysis.md`

The document must follow the template:

`.opencode/skills/business-analysis/business-analysis-template.md`

The output document must contain:

1. Business Purpose
2. Actors
3. Candidate Entities
4. Attributes
5. Relationships
6. Cardinalities
7. Business Rules
8. Assumptions and Ambiguities

Do not omit any required section.

---

## Validation Checklist

Before saving the document, verify that:

* Business purpose is documented.
* At least one actor is identified.
* Every entity has a description.
* Every entity has candidate attributes.
* Every relationship has participating entities.
* Every relationship has cardinality.
* Explicit business rules are identified.
* Derived business rules are identified when applicable.
* Ambiguities are documented.
* Output follows the required template structure.
* Workflow steps are not incorrectly modeled as independent relationships.
* Relationships represent associations between business objects rather than stages of the same business process.
* Business processes are modeled cohesively and are not fragmented into multiple entities or relationships without justification.

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
