---
name: concurrency-design-final
description: Create a comprehensive, production-ready, deeply technical concurrency design document for Task 11 using specific MS SQL Server mechanisms.
compatibility: opencode
---

# Concurrency Design Skill 

## Skill Objective

* Analyze the business requirement changes to identify concurrency-sensitive business rules.

* Identify concurrent business operations that may execute simultaneously.

* Identify realistic concurrency conflicts introduced by the updated requirements.

* Analyze the business rules and invariants threatened by each conflict.

* Recommend appropriate Microsoft SQL Server concurrency mechanisms for each conflict, using the least restrictive mechanism that preserves the required business invariant.

* Produce a structured concurrency design document that serves as the foundation for implementing transactional consistency.

---

## Required Input Files

Read the following files:

* `req/business-requirement-change.md`
* `outputs/08-req-change-analysis-G7.md`

If an existing analysis already exists, also read:

* `outputs/11-concurrency-design-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `req/business-requirement-change.md`
* `outputs/08-req-change-analysis-G7.md`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the updated business requirements.
2. Read the requirement change analysis.
3. Identify business rules that may be violated under concurrent execution.
4. Identify concurrent business operations.
5. Identify realistic concurrency conflict scenarios.
6. Determine affected business rules and invariants.
7. Select appropriate Microsoft SQL Server concurrency mechanisms.
8. Generate the concurrency design documentation.

---

# Concurrency Design Rules

## Business Rule Identification Rules

### Rule BR1 — Concurrency-Sensitive Business Rule

A business rule is concurrency-sensitive when:

* It requires validation before data modification.
* It depends on the current state of shared business resources.
* It may become invalid if multiple transactions execute simultaneously.

Only analyze business rules that may be violated by concurrent execution.

---

## Concurrent Operation Rules

### Rule CO1 — Concurrent Operations

Identify every realistic pair (or group) of business operations that may execute simultaneously.

Do not limit the analysis to INSERT operations.

Possible operations include:

* SELECT
* INSERT
* UPDATE
* DELETE

Possible combinations include:

* INSERT vs INSERT
* INSERT vs UPDATE
* UPDATE vs UPDATE
* UPDATE vs DELETE
* SELECT vs UPDATE
* SELECT vs INSERT
* DELETE vs INSERT

Only retain scenarios that can realistically occur within the business workflow.

---

## Conflict Identification Rules

### Rule CF1 — Real Business Conflict

A concurrency conflict exists when concurrent execution may violate one or more business rules.

For every conflict identify:

* Business scenario
* Concurrent operations
* Shared business resources
* Violated business rules
* Business invariant that must be preserved

Describe conflicts using realistic business workflows rather than theoretical database anomalies.

---

## SQL Server Mechanism Rules

### Rule SQL1 — SQL Server Specific

Acceptable mechanisms include, but are not limited to:

### Isolation Levels (when required)

* READ COMMITTED
* REPEATABLE READ
* SERIALIZABLE

### Locking Hints (when appropriate)

* UPDLOCK
* HOLDLOCK
* READCOMMITTEDLOCK

---

### Rule SQL2 — Mechanism Selection

When multiple mechanisms are possible, recommend the least restrictive mechanism that preserves the required business invariant.

Possible mechanisms include:

* appropriate locking hints;
* transaction isolation levels;
* or a combination of both.

Only recommend an isolation level when it contributes to preserving the required invariant beyond SQL Server's default behavior.

---

## Design Rules

### Rule D1 — Design Only

This stage is responsible only for concurrency design.

Do not generate:

* SQL statements
* Transaction scripts
* Stored procedures
* Trigger implementations
* Pseudo code

Implementation belongs to later stages.

---

### Rule D2 — Traceability

Every identified conflict must be traceable to one or more business rules identified in the requirement change analysis.

Every recommended SQL Server mechanism must clearly reference the business rule(s) it protects.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Load Input Artifacts

Read:

* `req/business-requirement-change.md`
* `outputs/08-req-change-analysis-G7.md`

Treat the Requirement Change Analysis as the baseline.

---

### Step 2 — Identify Concurrency-Sensitive Business Rules

Review the updated business requirements and determine which business rules may be violated by concurrent execution.

---

### Step 3 — Identify Concurrent Operations

For each concurrency-sensitive business rule, identify all realistic concurrent operations that may interact.

Do not restrict the analysis to specific SQL operations.

---

### Step 4 — Analyze Concurrency Conflicts

For each identified conflict determine:

* Business scenario
* Concurrent operations
* Shared business resources
* Affected business rules
* Business invariant that must be preserved

Do not recommend implementation mechanisms during this step.

---

### Step 5 — Select SQL Server Concurrency Mechanisms

For each conflict determine:

* Recommended SQL Server mechanism
* Reason for selecting the mechanism
* Why weaker mechanisms are insufficient
* Expected trade-offs

---

### Step 6 — Validate Design Consistency

Verify that:

* Every conflict originates from a business rule.
* Every recommendation is supported by SQL Server concurrency mechanisms.
* No implementation details are introduced.
* Every recommendation is traceable to the identified business rules.

---

### Step 7 — Generate Concurrency Design

Produce the document following the required template.

Record:

* Concurrency-sensitive business rules
* Conflict scenarios
* Shared business resources
* Affected business rules
* Recommended SQL Server mechanisms
* Technical justifications
* Assumptions
* Open questions

---

## Important Rules

### Scope Restriction Rules

This stage is responsible only for concurrency design.

Do not:

* Modify business requirements.
* Redesign the ERD.
* Modify the logical schema.
* Recommend schema migration.
* Generate SQL implementation.
* Generate triggers or stored procedures.

---

### Design Independence Rule

Concurrency Design specifies how business consistency should be preserved.

It must not redesign the database structure.

---

### Requirement Evidence Rule

Every identified conflict must be classified as one of:

* Explicitly Required
* Directly Inferred
* Assumption

Assumptions must never be presented as confirmed business conflicts.

---

## Output Specification

Create or update:

`outputs/11-concurrency-design-G7.md`

The document must follow the template:

`.opencode/skills/concurrency-design/concurrency-design-template.md`

Do not omit any required section.

---

## Validation Checklist

* Every concurrency-sensitive business rule has been identified.
* Every conflict is traceable to one or more business rules.
* Concurrent operations are not limited to INSERT operations.
* Every conflict identifies the shared business resource.
* Every conflict identifies the affected business invariant.
* Every recommendation specifies the SQL Server mechanism(s) required to preserve the business invariant.
* Isolation levels are included only when they materially contribute to correctness.
* No SQL implementation is included.
* No pseudo code is included.
* No trigger or stored procedure implementation is included.
* Assumptions are clearly separated from confirmed findings.
* Open questions are clearly identified.
* The output follows the required template.

---

## 9. Error Handling 

If `req/business-requirement-change.md` and `outputs/08-req-change-analysis-G7.md` do not exist:

* Stop execution.
* Report the missing file.
