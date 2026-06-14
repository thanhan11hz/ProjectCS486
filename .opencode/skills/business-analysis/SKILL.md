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
* Description
* Responsibilities

### 3. Identify Candidate Entities

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

For each relationship:

* Participating entities
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

### Attribute Identification Rules

Attributes should:

* Describe an entity
* Be atomic whenever possible
* Avoid derived values unless required by the business

### Relationship Rules

Every identified relationship should:

* Connect valid entities
* Have a clear business meaning
* Include cardinality

### Business Rule Rules

Business rules should be:

* Testable
* Unambiguous
* Traceable to the requirements

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
