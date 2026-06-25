---
name: db-implementation
description: Transform logical database design into physical Microsoft SQL Server DDL scripts.
compatibility: opencode
---

# Database Implementation Skill

## Objective

Use this skill to transform the validated Logical Database Design into a physical database implementation for Microsoft SQL Server (T-SQL).

The output must include:
* SQL Data Definition Language (DDL) scripts.
* Database constraints (Primary Keys, Foreign Keys, Checks, Uniques).

The output will be used to deploy the actual database instance. No performance optimizations (like Indexes, Views, or Triggers) are required at this stage. No data input is required at this stage. The Logical Design is assumed to be complete and correct.

---

## Required Input Files

Read the following file:
* `outputs/03-logical-design-G7.md` (The authoritative source for entities, attributes, and relationships)

If a partial implementation already exists, also read:
* `outputs/05-db-implementation-G7.sql`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* `outputs/03-logical-design-G7.md`

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the Logical Database Design completely.
2. Identify the target Database Management System (DBMS) as Microsoft SQL Server (T-SQL).
3. Map logical data types to exact T-SQL physical data types (e.g., `NVARCHAR`, `DATETIME2`).
4. Establish execution order for table creation (Topological sort based on Foreign Key dependencies).
5. Apply naming conventions for tables, columns, constraints.
6. Implement structural constraints (NOT NULL, UNIQUE, DEFAULT).
7. Implement referential integrity actions (ON DELETE, ON UPDATE).
8. Design data validation rules (CHECK constraints).
9. Generate the consolidated physical T-SQL deployment script and seed data.

---

# Physical Implementation Rules

## Naming Convention Rules

### Rule N1 — Casing and Pluralization
* **Tables:** Use `snake_case` and **plural** nouns (e.g., `users`, `maintenance_records`).
* **Columns:** Use `snake_case` and **singular** nouns (e.g., `email`, `created_at`).
* **Primary Keys:** Name simply as `id` or `table_singular_id` (consistent across the script).
* **Foreign Keys:** Name as `table_singular_id` (e.g., `space_id` referencing `spaces.id`).

### Rule N2 — Constraint Naming
All explicit constraints must follow a strict prefix naming convention:
* **Primary Key:** `pk_<table_name>`
* **Foreign Key:** `fk_<table_name>_<referenced_table_name>`
* **Unique Constraint:** `uq_<table_name>_<column_name>`
* **Check Constraint:** `ck_<table_name>_<constraint_purpose>`

### Rule N3 — Reserved Words
* Avoid using SQL Server reserved keywords for table or column names. If a table or column name is a reserved word, you may append an underscore (e.g., `order_`). Popular reserved words include
---

## Data Type Mapping Rules (MS SQL Server Specific)

### Rule T1 — String and Text Handling
* This rule does not apply to IDs, which are handled separately in Rule T4.
* Use `VARCHAR(N)` or `CHAR(N)` ONLY for non-Unicode fields, emails, and status tokens.
* Use `NVARCHAR(N)` or `NVARCHAR(MAX)` when the text might not be in English(e.g., names, descriptions,comments). 

### Rule T2 — Numbers, Booleans, and Dates
* **Auto-increment Keys:** If an ID needs to be auto-generated, use `INT IDENTITY(1,1)` or `BIGINT IDENTITY(1,1)`. Do not use `SERIAL` or `AUTO_INCREMENT`. (Note: If the logical design uses string identifiers, stick to `VARCHAR`/`NVARCHAR` without IDENTITY).
* **Booleans:** Use `BIT` (where `1` is True, `0` is False). Do not use `BOOLEAN`.
* **Dates:** Use `DATETIME2` for modern date/time storage, or `DATE` for calendar dates.
* **Financial Data:** Use `DECIMAL(p,s)` or `NUMERIC(p,s)`. Never use `FLOAT` for exact values.
### Rule T3 — Batch Separation (GO)
* **Purpose:** GO is a batch separator, not a SQL command. Use it on a standalone line to isolate execution blocks and prevent cross-batch errors.

* **Cleanup Isolation:** Always append GO immediately after the complete block of DROP TABLE statements.

* **DDL Isolation:** Append GO after every single CREATE TABLE statement to ensure the schema is committed to the database engine before dependent tables are created.

* **DML Isolation:** Append GO after completing a group of INSERT INTO statements for a specific table in the seed data block.---

### Rule T4 — Decide IDs type
* If the ID is for external IDs(IDs that can be used or input outside the system, might depend on the outside), use `VARCHAR` or `NVARCHAR`, with appropriate length.(eg. User IDs, Space codes, etc.)
* If the ID is for internal IDs(IDs that are only used inside the system, and not exposed outside), use `INT` or `BIGINT` with `IDENTITY(1,1)`.(eg. Facility, Maintenance record IDs, etc.)

## Execution Process

Perform the following steps in order.

### Step 1 — Load Logical Schema
Read: `outputs/03-logical-design-G7.md`
Extract:
* Final relations/tables.
* Attribute names and logical types.
* Primary keys and Foreign keys mapping.
* Business rules that map to technical constraints.

Treat the Logical Design as the authoritative source. Do not introduce new entities or attributes. Take the logical design of the crowfoot diagram as the reference of truth for the physical implementation.

---

### Step 2 — Resolve Dependency Graph (Table Ordering)
Analyze the foreign key relationships to determine the exact execution order:
* Independent tables (no FKs) must be created **first**.
* Dependent tables (with FKs) must be created **last**.
* Generate cleanup scripts at the top of the file to drop tables in **reverse** dependency order using T-SQL syntax to ensure idempotency:
  `IF OBJECT_ID('table_name', 'U') IS NOT NULL DROP TABLE table_name;`

---

### Step 3 — Physical Columns Mapping
Translate the logical attributes into T-SQL physical DDL definitions:
* Select appropriate T-SQL data types based on Rule T1 and T2.
* Enforce `NOT NULL` on all mandatory attributes determined during logical analysis.

---

### Step 4 — Implement Constraints
Embed business logic directly into the table definitions:
* Append `CHECK` constraints for value ranges (e.g., `CONSTRAINT ck_spaces_capacity CHECK (capacity > 0)`).
* Append `UNIQUE` constraints for non-key columns that must remain distinct.
* Append `FOREIGN KEY` constraints with explicit `ON DELETE` behavior (e.g., `CASCADE` for weak entities, `NO ACTION` otherwise).

### Step 5 — Business Rules Documentation
Document all business rules and constraints that were not implemented in the output SQL file as comments at the end of the file. Include:
* The rule description.
* The reason for not implementing it (e.g., "This rule is enforced at the application level, not the database level").


## Important Rules
### Data Definition ONlY
This skill is responsible for generating only the Data Definition Language (DDL) scripts. Do not generate any seed data or Data Manipulation Language (DML) scripts. The seed data will be generated in a later stage.

### Scope Restrictions Rules
This stage is not responsible for:
* Re-structuring the logical schema or modifying entities.
* Database performance optimizations (Do NOT generate `CREATE INDEX`, Views, or Triggers).
* Table normalization (Assumed completed in previous stages).

### Database Idempotency Rule
The output script must be completely idempotent. Re-running the script multiple times on an instance must execute seamlessly without throwing primary key conflicts or duplicate schema errors.
To do this, at the start of the script, change the database context to `master` and drop the existing database if it exists like this SQL Server syntax:
```sql
USE [master];
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = <'database_name'>)
BEGIN
    ALTER DATABASE <'database_name'> SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE <'database_name'>;
END
GO
```


### Example Usage Rules
Examples used in this skill are illustrative only. Do not reuse example entities, columns, or business rules from the examples. Always derive results exclusively from the provided logical design.

---

## Output Specification

Create
`outputs/05-db-implementation-G7.sql`
if it does not exist. If it exists, update it.

The file must structure as follows:
1. **Header Block:** Metadata detailing MS SQL Server target and version.
2. **Cleanup Schema Block:** Drop existing tables in reverse dependency order.
3. **Table Creation Block:** Sequentially order the execution of `CREATE TABLE` scripts inclusive of all inline constraints.
4. **Seed Data Block:** Comprehensive testing insert queries.

---

## Validation Checklist

Before saving:
* No seed data is included in the output.
* Datatype matching correct for all attributes with the data type mapping rules. All IDs must follow the decided ID type rules.
* Naming conventions for tables, columns, and constraints are strictly followed, no name conflicts with reserved words or keywords, of Microsoft SQL Server.
* The SQL script executes without syntax errors on Microsoft SQL Server.
* No explicit Indexing (`CREATE INDEX`) is included in the output.
* Proper T-SQL data types are used (`NVARCHAR`, `BIT`, `DATETIME2`).
* Table generation follows the dependency sequence (no forward-reference FK errors).
* All constraints (`PK`, `FK`, `CHECK`, `UNIQUE`) have clean, systematic prefix names and follow the logical schema.
* Drop statements use `IF OBJECT_ID('table_name', 'U') IS NOT NULL`.
* Unicode strings in seed data are prefixed with `N`.

---

## Error Handling

If `outputs/03-logical-design-G7.md` does not exist:
* Stop execution.
* Report the missing file.

If conflicting entity definitions are found:
* Record the conflict.
* Select the most reasonable interpretation based on standard relational modeling.