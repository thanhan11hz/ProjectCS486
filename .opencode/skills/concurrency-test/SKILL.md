---
name: concurrency-test
description: implement concurrency test 
compatibility: opencode
---

# Concurrency Test Skill

## Objective

Use this skill to create SQL server script for testing concurrency enforcement.

The output must include:
* A folder containing SQL Script for testing each concurrency conflict

The output will be used to contrast the operation with and without concurrency enforcement for each concurrency conflict.

---

## Required Input Files

Read the following file:
* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`
* `outputs/11-concurrency-design-G7.md` 
* `outputs/12-concurrency-implementation-G7.sql`
* `.opencode/skills/concurrency-test/concurrency-test-template.md`


If a previous run of this skill has already created the following folder and it is not empty, also read the files in it:
* `outputs/13-concurrency-tests-G7/`

Do not read any other unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`
* `outputs/11-concurrency-design-G7.md` 
* `outputs/12-concurrency-implementation-G7.sql`
* `.opencode/skills/concurrency-test/concurrency-test-template.md`

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Using the structure in `.opencode/skills/concurrency-test/concurrency-test-template.md`, create or update files in the folder:

* `outputs/13-concurrency-tests-G7/`

Do not omit any required section.

---

# Concurrency Test Step

## Step 1: Understand the Concurrency Conflict and Related Transaction

From the input files, read and understand each concurrency conflict, related operation, and how its enforcement is implemented in SQL script

## Step 2: Data Initialization

Based on the tables created in `outputs/05-db-implementation-G7.sql` and `outputs/10-schema-migration-G7.sql`, prepare the initial data to run the experiment

## Step 3: Generate Concurrency Test Cases

**Note:** SQL script are for SQL Server. **RAISERROR** does not accept an expression for the message parameter, so the meassage should not be separated into sum of multiple strings.
**IMPORTANT:** To simulate each conflict scenario, for each case with and without concurrency enforcement, create 2  separate SQL script files, so that they can be run in 2 separate sessions to recreate the respective conflict scenario. **Remember** to insert **DELAY statements**  to the procedure between check and data modification, instead of inserting to the testing SQL scripts. The **INSERT** statement must be compatible with initial data in Step 2.

Create a separate subfolder for each concurrency conflict.

For every concurrency conflict, generate the following artifacts:

1. Procedure with Concurrency Enforcement

- Reuse the stored procedure from `outputs/12-concurrency-implementation-G7.sql`.
- Create two SQL scripts that simulate the scenario of the target concurrency conflict.
- Ensure the scripts demonstrate that the implemented concurrency control mechanism correctly prevents the conflict.

2. Procedure without Concurrency Enforcement

- Create a copy of the stored procedure from `outputs/12-concurrency-implementation-G7.sql` with all concurrency control mechanisms removed (isolation levels and locking hints).
- Create two SQL scripts that simulate the same concurrency conflict.
- Ensure the scripts demonstrate that the concurrency conflict occurs when no concurrency control mechanism is present.

---