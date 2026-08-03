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
* Update entity definitions, attributes, relationships, cardinalities, participation constraints, and business rules as required.
* Update the relational schema to remain consistent with the revised conceptual model.
* Document all design changes together with their rationale and traceability to the approved requirement changes.
* Validate that the updated conceptual and logical models remain complete, consistent, and compliant with the business requirements.
* Produce the updated ERD and logical design as the foundation for schema migration and database implementation.

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

The following file must exist:

* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`
* `outputs/08-req-change-analysis-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Create or update:

`outputs/09-updated-erd-and-logical-design-G7.md`

---

## Error Handling

If `outputs/02-erd-design-G7.md`, `outputs/03-logical-design-G7.md` and `outputs/08-req-change-analysis-G7.md` do not exist:

* Stop execution.
* Report the missing file.