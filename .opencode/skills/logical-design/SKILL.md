---

name: logical-design
description: Transform the conceptual ERD into a relational schema suitable for database implementation
compatibility: opencode
-----------------------

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

Read:

* `docs/02-erd-design.md`

If available, also read:

* `docs/01-business-requirement-analysis.md`

Do not read unrelated files.

---

## Prerequisites

The following file must exist:

* `docs/02-erd-design.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the conceptual ERD completely.
2. Identify all entities.
3. Identify all attributes.
4. Identify all relationships.
5. Identify all cardinalities.
6. Identify participation constraints.
7. Convert the conceptual model into a relational model.

---

## Methodology

### 1. Map Strong Entities

Create one relation for each strong entity.

For each relation:

* Relation name
* Attributes
* Primary Key

### 2. Map Weak Entities

Create a relation for each weak entity.

Include:

* Partial key
* Owner entity key
* Composite primary key

### 3. Map 1:1 Relationships

Choose the most appropriate relation to receive the foreign key.

Document the design decision.

### 4. Map 1:N Relationships

Place the foreign key on the N-side relation.

### 5. Map M:N Relationships

Create an associative relation.

Include:

* Foreign keys from participating relations
* Relationship attributes
* Composite primary key when appropriate

### 6. Map Multivalued Attributes

Create a separate relation.

### 7. Map Composite Attributes

Decompose into atomic attributes.

### 8. Identify Candidate Keys

Document all meaningful candidate keys.

### 9. Define Integrity Constraints

Identify:

* Entity integrity
* Referential integrity
* Key constraints

---

## Design Rules

### General Rules

The logical model must remain DBMS-independent.

Do not include:

* SQL syntax
* CREATE TABLE statements
* Data types
* CHECK constraints
* Triggers
* Views

### Relation Rules

Every relation must have:

* Name
* Attributes
* Primary key

### Key Rules

Every relation must have:

* Primary Key

Candidate Keys should be documented when known.

### Foreign Key Rules

Every relationship must be represented through:

* Foreign key
* Associative relation

as appropriate.

### Relationship Mapping Rules

1:1 relationships:

* Implement using foreign keys.

1:N relationships:

* Foreign key on N-side.

M:N relationships:

* Associative relation required.

### Attribute Rules

Attributes should be:

* Atomic
* Non-repeating

Composite attributes must be decomposed.

---

## Output Specification

Create or update:

`docs/03-logical-design.md`

The output must follow:

`.opencode/skills/logical-design/logical-design-template.md`

Do not omit required sections.

---

## Validation Checklist

Before saving:

* Every conceptual entity becomes a relation.
* Every relation has a primary key.
* Foreign keys are identified.
* M:N relationships are resolved.
* Candidate keys are documented.
* Composite attributes are decomposed.
* Multivalued attributes are resolved.
* Referential integrity is represented.
* No SQL syntax appears.
* Logical schema is complete.

---

## Error Handling

If the conceptual ERD is missing:

* Stop execution.
* Report the missing file.

If cardinalities are ambiguous:

* Document the assumption.
* Justify the mapping decision.

If multiple mappings are possible:

* Select the simplest valid design.
* Record the rationale.
