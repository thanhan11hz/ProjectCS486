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

1. Analyze business requirements to identify the business purpose, actors, entities, attributes, relationships, cardinalities, and business rules.
2. Produce conceptual ERD using Flowchart notation showing the main entities, attributes, relationships, cardinalities, and participation constraints.
3. Convert ERD into relational schema using Crow's Foot notation with relations, attributes, primary keys, foreign keys, candidate keys, and key constraints.
4. Validate the relational schema representing ERD, business rules, key constraints, referential integrity constraint
5. Implement the database using SQL DDL with tables, keys, constraints, checks, and default values where appropriate
6. Generate realistic sample data to support testing of normal operations and important exceptional cases

The user may request any stage individually.

The agent must only execute the requested stage unless explicitly instructed to continue to later stages.

## Required Outputs

- `docs/01-business-req-analysis.md`
- `docs/02-erd-design.md`
- `docs/03-logical-design.md`
- `docs/04-design-validation.md`
- `docs/05-db-definition.sql`
- `docs/06-sample-data.sql`
- `docs/07-query-design.sql`

## DBMS

Use Microsoft SQL Server unless the user specifies another DBMS.

## Design Rules

- Record assumptions explicitly.
- Record open questions explicitly.
- Preserve traceability from requirement → entity → relationship → table → constraint.
- Use Mermaid `erDiagram` flowchart for ERD.
- Do not silently invent business rules.
