---
name: schema-migration
description: Generate SQL migration scripts to evolve the old database schema while preserving existing data whenever possible.
compatibility: opencode
---

# Schema Migration Skill

## Objective

* Compare the Phase 1 database implementation with the updated Phase 2 logical design.

* Identify every schema change required to evolve the database.

* Generate an idempotent Microsoft SQL Server migration script.

* Preserve existing data whenever possible.

* Implement newly introduced business constraints that belong to the schema layer.

* Exclude concurrency control mechanisms, which belong to the Concurrency Design stage.

* Produce a production-ready migration script following Microsoft SQL Server best practices.

---

## Required Input Files

Read the following files:

* `outputs/05-db-implementation-G7.sql`
* `outputs/08-req-change-analysis-G7.md`
* `outputs/09-updated-erd-and-logical-design-G7.md`

If an existing analysis already exists, also read:

* `outputs/10-schema-migration-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/05-db-implementation-G7.sql`
* `outputs/08-req-change-analysis-G7.md`
* `outputs/09-updated-erd-and-logical-design-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Create or update:

* `outputs/10-schema-migration-G7.md`

---

## Error Handling

If `outputs/05-db-implementation-G7.sql`, `outputs/08-req-change-analysis-G7.md` and `outputs/09-updated-erd-and-logical-design-G7.md` do not exist:

* Stop execution.
* Report the missing file.