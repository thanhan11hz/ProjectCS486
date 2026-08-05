---
name: concurrency-implementation
description: implement concurrency enforcement 
compatibility: opencode
---

# Concurrency Implementation Skill

## Objective

Use this skill to create SQL server script implementing the concurrency enforcement based on the concurrency design.

The output must include:
* SQL Concurrency Script

The output will be used to implement transactions related to these concurrency conflict mentioned in the concurrency design. 

---

## Required Input Files

Read the following file:
* `outputs/11-concurrency-design-G7.md` 
* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`

If a previous implementation of the SQL seed script already exists, also read:
* `outputs/12-concurrency-implementation-G7.sql`

Do not read any other unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* `outputs/11-concurrency-design-G7.md` 
* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Create or update:

`outputs/12-concurrency-implementation-G7.sql`

Do not omit any required section.

---