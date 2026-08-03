---
name: update-erd-logical
description: Update the ERD and relational schema to incorporate business requirements change while preserving the existing database design.
compatibility: opencode
---

# Update ERD and Logical Schema Skill

## Objective



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