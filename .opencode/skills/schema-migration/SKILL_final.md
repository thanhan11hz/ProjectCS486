---
name: schema-migration-final
description: Generate SQL migration scripts to evolve the old database schema while preserving existing data whenever possible.
compatibility: opencode
---

# Schema Migration Skill 

## Objective

* Compare the old database implementation with the updated logical design.

* Identify every schema change required to evolve the database.

* Generate an idempotent Microsoft SQL Server migration script.

* Preserve existing data whenever possible.

* Implement newly introduced business constraints using appropriate SQL Server mechanisms, including declarative constraints and triggers.

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

## Discovery Process

1. Read the Phase 1 database implementation.
2. Read the Requirement Change Analysis.
3. Read the updated logical design.
4. Compare the Phase 1 schema with the updated schema.
5. Identify required schema modifications.
6. Identify obsolete schema objects.
7. Identify new schema-level business constraints.
8. Determine implementation order.
9. Generate the schema migration script.

---

# Schema Migration Rules

## Schema Evolution Rules

### Rule S1 — Schema Difference

Identify every schema change required between Phase 1 and Phase 2.

Possible changes include:

* New tables
* Removed tables
* New columns
* Removed columns
* Modified data types
* Modified nullability
* New relationships
* Removed relationships

Only generate changes supported by the updated logical design.

---

### Rule S2 — Schema-Level Constraints

Implement all business constraints that belong to the schema layer.

Examples include:

* PRIMARY KEY
* FOREIGN KEY
* UNIQUE
* CHECK
* DEFAULT

---

### Rule S3 — Existing Object Cleanup

Remove obsolete schema objects that are no longer consistent with the updated requirements.

Possible objects include:

* CHECK constraints
* FOREIGN KEY constraints
* UNIQUE constraints
* DEFAULT constraints

Only remove objects that directly conflict with the updated logical design.

---

## Migration Rules

### Rule M1 — Idempotency

Every schema modification must be safely executable multiple times.

Every DDL statement must be protected by an existence check such as:

* IF EXISTS
* IF NOT EXISTS

The script must never fail when executed repeatedly.

---

### Rule M2 — Data Preservation

Preserve existing data whenever possible.

Avoid destructive schema modifications unless explicitly required.

When introducing new mandatory columns into populated tables:

* Determine whether the business requirements provide a valid value for existing records.
* If a valid value cannot be determined from the requirements, do not assign an arbitrary default value.
* Instead, either:
  * temporarily allow NULL values,
  * perform an explicit data migration based on documented assumptions, or
  * document that manual data migration is required before enforcing NOT NULL.

Any migration assumptions must be explicitly documented.

---

### Rule M3 — Dependency Order

Generate schema modifications in a valid dependency order.

Typical order includes:

1. Remove obsolete constraints
2. Add new columns
3. Modify existing columns
4. Create new tables
5. Add relationships
6. Add schema constraints

The generated script must execute without dependency violations.

---

### Rule M4 — Naming Consistency

All newly created database objects must follow the existing naming conventions established in the Phase 1 implementation.

---

### Rule M5 — Semantic Default Values

Temporary DEFAULT values used during migration shall preserve the original business semantics whenever possible.

The migration should infer suitable default values from the original business requirements rather than assigning arbitrary placeholder values.

If no semantically correct default exists, document the migration assumption or require manual data migration.

---

## Business Constraint Rules

### Rule BC1 — Declarative Constraints

Implement business rules that can be enforced directly through SQL Server declarative constraints.

Examples include:

* PRIMARY KEY
* FOREIGN KEY
* UNIQUE
* CHECK
* DEFAULT

---

### Rule BC2 — Trigger-Based Constraints

Implement all business rules that cannot be enforced using declarative constraints through SQL Server triggers.

Typical examples include:

* Validation involving multiple rows
* Validation involving multiple tables
* Aggregate constraints
* Temporal constraints
* Automatic maintenance of derived data
* Cross-entity business rules

Triggers shall reject any operation that violates the corresponding business rule by raising an appropriate SQL Server error and preventing the modification from being committed.

---

### Rule BC3 — Trigger Execution

Triggers shall be created on every table whose INSERT, UPDATE, or DELETE operations may violate a business rule.

If the same business rule may be violated through modifications to multiple tables, implement triggers on each relevant table.

Each trigger shall validate only the business rules affected by the triggering operation.

---

### Rule BC4 — Trigger Failure

When a trigger detects a business rule violation, it shall:

* Raise an appropriate SQL Server error.
* Prevent the violating modification.
* Leave the current transaction in a consistent state.

Triggers shall not leave partial modifications in the database.

---

### Rule BC5 — Concurrency Independence

Triggers implement business rule validation only.

They shall not implement transaction isolation, locking hints.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Load Input Artifacts

Read:

* `outputs/05-db-implementation-G7.sql`
* `outputs/08-req-change-analysis-G7.md`
* `outputs/09-updated-erd-and-logical-design-G7.md`

Treat the Phase 1 implementation as the baseline.

---

### Step 2 — Identify Schema Changes

Determine:

* Added schema objects
* Removed schema objects
* Modified schema objects

Only include changes required by the updated logical design.

---

### Step 3 — Identify Business Constraints

Determine which business rules should be implemented using:

* Declarative constraints
* Triggers

For every business rule that cannot be enforced declaratively, generate the corresponding trigger implementation.

---

### Step 4 — Generate Migration Strategy

Determine the correct execution order for all schema modifications.

Ensure that dependency constraints are satisfied.

---

### Step 5 — Generate Migration Script

Generate an idempotent Microsoft SQL Server migration script.

The script may include:

* Cleanup
* Schema evolution
* Declarative constraints
* Trigger creation
* Migration assumptions

Every business rule that requires trigger-based validation shall be fully implemented.

---

### Step 6 — Validate Migration

Verify that:

* Every schema change is supported by the updated logical design.
* Every DDL statement is idempotent.
* Existing data is preserved whenever possible.
* Object dependencies are respected.
* Only schema-level constraints are implemented.

---

## Important Rules

### Scope Restriction Rules

This stage is responsible only for schema migration.

Do not:

* Redesign the ERD.
* Modify business requirements.
* Implement concurrency control.
* Recommend isolation levels.
* Recommend locking strategies.

---

### Traceability Rule

Every schema modification must be traceable to:

* Requirement Change Analysis
* Updated Logical Design

---

## Output Specification

Create or update:

`outputs/10-schema-migration-G7.md`

The generated script should contain:

* Script metadata
* Cleanup section
* Schema evolution section
* Constraint implementation section

---

## 8. Validation Checklist

Before saving:

* Every schema modification is supported by the updated logical design.
* Every obsolete object is safely removed.
* Every DDL statement is idempotent.
* Existing data is preserved whenever possible.
* Dependency order is correct.
* Naming conventions are consistent. 
* Only schema-level constraints are implemented.
* The output follows the required structure.
* Every declarative constraint is correctly implemented.
* Every required trigger is implemented.
* Every trigger is attached to the appropriate table(s).
* Every trigger rejects operations that violate the corresponding business rule.
* Default values preserve existing business semantics.
* Migration assumptions are explicitly documented.
* No arbitrary default values are introduced.

---

## 9. Error Handling Guidelines

If `outputs/05-db-implementation-G7.sql`, `outputs/08-req-change-analysis-G7.md` and `outputs/09-updated-erd-and-logical-design-G7.md` do not exist:

* Stop execution.
* Report the missing file.