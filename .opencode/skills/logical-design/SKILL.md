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

Read the following files:

* `outputs/01-business-requirement-analysis-G7.md`
* `outputs/02-erd-design-G7.md`

If an existing analysis already exists, also read:

* `outputs/03-logical-design-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/01-business-requirement-analysis-G7.md`
* `outputs/02-erd-design-G7.md`

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

## Execution process



---

## Output Specification

Create or update:

`outputs/03-logical-design-G7.md`

The document must follow the template:

`.opencode/skills/logical-design/logical-design-template.md`

Do not omit any required section.

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

If `outputs/01-business-requirement-analysis-G7.md` and `outputs/02-erd-design-G7.md` do not exist:

* Stop execution.
* Report the missing file.

If cardinalities are ambiguous:

* Document the assumption.
* Justify the mapping decision.

If multiple mappings are possible:

* Select the simplest valid design.
* Record the rationale.
