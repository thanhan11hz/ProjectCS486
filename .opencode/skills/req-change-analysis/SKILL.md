---
name: req-change-analysis
description: Analyze business requirement changes by identifying affected entities, relationships, business rules, and potential concurrency conflicts.
compatibility: opencode
---

# Requirement Change Analysis Skill

## Objective

* Compare the Phase 1 and Phase 2 business requirements to identify all requirement changes.

* Identify affected entities, attributes, relationships, and business rules.

* Analyze the impact of the requirement changes on the existing database design.

* Identify potential concurrency conflicts introduced by the new requirements.

* Document the required design changes needed to support the updated requirements.

* Produce a structured requirement change analysis that serves as the foundation for updating the ERD, logical schema, schema migration, and concurrency design.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`
* `req/business-requirement-change.md`
* `outputs/01-business-req-analysis-G7.md`

If an existing analysis already exists, also read:

* `outputs/08-req-change-analysis-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `req/business-requirement.md`
* `req/business-requirement-change.md`
* `outputs/01-business-req-analysis-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

## Output Specification

Create or update:

`outputs/08-req-change-analysis-G7.md`

---

## Error Handling

If `req/business-requirement.md`, `req/business-requirement-change.md` and `outputs/01-business-req-analysis-G7.md` do not exist:

* Stop execution.
* Report the missing file.