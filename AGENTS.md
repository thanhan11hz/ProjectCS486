# AGENTS.md — cs486-demo

CS486 database systems teaching demo. Repository is empty; expect code to be added during sessions.

## Recurring context

- Root directory: <!-- YOUR ROOT DIRECTORY -->
- This is a demo project, not production.
- Run `ls -la` to detect new files before assuming anything exists.

# Database Design Agent Rules

This project transforms business requirements into database design artifacts.

<!---YOU COULD CHANGE THE FOLLOW SECTIONS --->
## Workflow Order

The agent supports the following independent stages:

### Phase 1 – Initial Database Design

1. Analyze business requirements to identify:
   - Business purpose
   - Actors
   - Entities
   - Attributes
   - Relationships
   - Cardinalities
   - Business rules

2. Produce a conceptual ERD using Mermaid `erDiagram`.

3. Convert the ERD into a relational schema.

4. Validate the relational schema against the ERD and business rules.

5. Implement the database using Microsoft SQL Server DDL.

6. Generate realistic sample data.

7. Design meaningful business SQL queries.

### Phase 2 – Database Evolution

8. Analyze requirement changes by identifying:
   - Affected entities
   - Affected relationships
   - Affected business rules
   - Required schema changes
   - Potential concurrency conflicts

9. Update the ERD and relational schema to support the new requirements while preserving the existing design where appropriate.

10. Generate schema migration scripts that evolve the Phase 1 database instead of recreating it.

11. Design concurrency control strategies for booking, approval, maintenance, and other critical operations.

12. Implement concurrency control using appropriate SQL Server mechanisms such as transactions, isolation levels, locking hints, triggers, or row versioning.

13. Develop concurrency test scenarios to verify correctness under simultaneous transactions.

14. Generate large-scale, realistic test data for concurrency and performance testing.

15. Analyze execution plans and recommend indexing strategies to improve query performance.

16. Design analytical SQL queries for reporting and business intelligence.

The user may request any stage independently.

The agent must execute only the requested stage unless explicitly instructed to continue.

## Required Outputs

### Phase 1

- `outputs/01-business-req-analysis-G7.md`
- `outputs/02-erd-design-G7.md`
- `outputs/03-logical-design-G7.md`
- `outputs/04-design-validation-G7.md`
- `outputs/05-db-definition-G7.sql`
- `outputs/06-sample-data-G7.sql`
- `outputs/07-query-design-G7.sql`

### Phase 2

- `outputs/08-requirement-change-analysis-G7.md`
- `outputs/09-updated-erd-and-logical-design-G7.md`
- `outputs/10-schema-migration-G7.sql`
- `outputs/11-concurrency-design-G7.md`
- `outputs/12-concurrency-implementation-G7.sql`
- `outputs/13-concurrency-tests-G7/`
- `outputs/14-data-generator-G7/`
- `outputs/15-index-tuning-report-G7.md`
- `outputs/16-analytical-queries-G7.sql`

## DBMS

Use Microsoft SQL Server unless the user specifies another DBMS.

## Design Rules

- Preserve traceability from:
  - Requirement
  - Business rule
  - Entity
  - Relationship
  - Table
  - Constraint
  - SQL implementation

- Record all assumptions explicitly.

- Record unresolved questions explicitly.

- Do not silently invent business rules.

- Reuse existing Phase 1 artifacts whenever possible.

- Treat Phase 2 as a migration of the existing design rather than a complete redesign.

- Prefer incremental schema evolution (`ALTER`, migration scripts, new indexes, new constraints) over recreating the database.

- Clearly document every design change introduced in Phase 2 together with its rationale.

- When implementing concurrency, explain why the selected mechanism (transaction, isolation level, locking strategy, optimistic concurrency, etc.) is appropriate.

- When tuning performance, justify every recommended index using workload characteristics and execution plans.
