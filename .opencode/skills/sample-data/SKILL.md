---
name: sample-data
description: Create Microsoft SQL Server seed script to insert realistic sample data into the database
compatibility: opencode
---

# Sample Data Preparation Skill

## Objective

Use this skill to create a SQL seed script which can be use to insert sample data into the implemented database for Microsoft SQL Server.

The output must include:
* SQL Seed Script

The output will be used to insert realistic sample data into the database instance. No performance optimizations (like Indexes, Views, or Triggers) are required at this stage. The Database Implementation is assumed to be complete and correct.

---

## Required Input Files

Read the following file:
* outputs/05-db-implementation-G7.sql (The database implementation SQL file)

If a previous implementation of the SQL seed script already exists, also read:
* outputs/06-sample-data-G7.sql

Do not read any other unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* outputs/05-db-implementation-G7.sql

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

# Data Generation Process

## Step 1: Understand the Database Schema

- Read the file outputs/05-db-implementation-G7.sql
- Identify:
  - All tables
  - Attributes for each table
  - Primary keys, foreign keys, and candidate keys
  - Relationships (1-1, 1-N, N-M)
  - Constraints and business rules

If the file is missing:
- Stop execution
- Report the missing prerequisite

---

## Step 2: Determine Insertion Order

Insert data based on dependency:

1. Independent tables (no foreign keys)
2. Parent tables (referenced by others)
3. Child tables (contain foreign keys)
4. Bridge tables (many-to-many relationships)

This prevents foreign key violations.

---

## Step 3: Design Realistic Data

Generate data that reflects real-world usage:

- Use meaningful values (names, emails, categories)
- Generate realistic dates (for example, within the past year)
- Apply weighted distributions (for example, more active than inactive)
- Ensure values follow domain logic (for example, participants must be positive)

---

## Step 4: Enforce Domain-Specific Rules

### Name Generation
- Use at least 40 to 60 first names and 20 to 30 last names
- Combine names randomly
- Shuffle final results
- Do not use random strings

### Departments
Only allow computer science related departments:
- Computer Science
- Software Engineering
- Data Science
- Artificial Intelligence
- Cybersecurity
- Information Systems
- Computer Networks
- Human-Computer Interaction

Do not use generic departments like HR or Marketing.

### Buildings
- Allowed values: A, B, C, D, E, F only

### Capacity
- Must be divisible by 5
- Usually between 40 and 50
- Auditoriums between 200 and 300
- Rare variation allowed

### Booking Status Distribution
- Approved: about 60 to 70 percent
- Completed: about 20 to 30 percent
- Rejected: at least 5 to 10 percent

### Rejected Bookings
- Must include a rejection reason
- Use a predefined reason list such as:
  - Scheduling conflict
  - Capacity exceeded
  - Duplicate request
  - Invalid booking details
  - Maintenance issue
- Rejection reason must be NULL for non-rejected bookings
- Rejection reason must NOT be NULL for rejected bookings

### Maintenance Records
- Most records should be marked as Completed
- Use at least 8 to 10 different result notes
- Result note must:
  - Be present for completed records
  - Be NULL for incomplete records

---

## Step 5: Enforce Business Rules

Translate business rules into data logic:

- Only pending bookings can be approved
- Completed bookings must have valid session data
- Ensure correct NULL and NOT NULL conditions
- Avoid invalid combinations of data

Use conditional logic and filtering where necessary.

---

## Step 6: Use SQL Server Randomization

Use built-in functions:

- NEWID() for randomness
- CHECKSUM(NEWID()) for integers
- RAND() for floating-point values
- DATEADD() for generating dates
- ABS() and modulo (%) for controlling ranges

---

## Step 7: Use Set-Based Data Generation

- Do not use row-by-row inserts
- Use:
  - TOP (1000) or more
  - CROSS JOIN
  - system tables such as sys.objects

Example:

INSERT INTO Users (...)
SELECT TOP (1000) ...
FROM sys.objects a
CROSS JOIN sys.objects b;

---

## Step 8: Enforce Data Volume

Minimum required sizes:

- Users: 500 to 1000 rows
- Spaces: 50 to 100 rows
- Facilities: 10 to 20 rows
- Bookings: 1000 to 3000 rows
- Sessions: 1000 to 3000 rows
- Approvals: 500 to 2000 rows
- Maintenance: 500 to 1000 rows
- Bridge tables: scale with relationships

Datasets with fewer than 100 rows are not acceptable.

---

## Step 9: Maintain Referential Integrity

- Ensure all foreign key values exist in parent tables
- Assign foreign keys from valid existing records
- Maintain realistic relationships:
  - Some users have many bookings
  - Some users have few bookings

No orphan records are allowed.

---

## Step 10: Include Edge Cases

Include:

- NULL values where allowed
- Boundary values (minimum and maximum limits)
- Rare conditions such as:
  - cancelled bookings
  - inactive users
- Constraint edge cases

---

## Step 11: Produce Final SQL Script

The final script must:

- Follow the correct insertion order
- Use efficient set-based operations
- Respect all constraints and business rules
- Generate large datasets

Optional:
- Wrap in transactions
- Temporarily disable and re-enable constraints
- Add comments for clarity

The script must be fully executable and reusable.

---

## Final Rules

- Follow all steps in order
- Do not skip validation or business rules
- Prioritize correctness before scale
- Ensure each main table has at least 500 rows
- Ensure data is realistic and consistent

---

## Output Specification

Create or update:

outputs/06-sample-data-G7.sql

Do not omit any required section.

---

## Error Handling

If outputs/05-db-implementation-G7.sql do not exist:

* Stop execution.
* Report the missing file.