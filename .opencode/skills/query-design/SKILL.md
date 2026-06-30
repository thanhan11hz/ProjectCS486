---
name: query-design
description: Design realistic MS SQL queries that simulate the business questions in the real world
compatibility: opencode
---

# Query Design Skill

## Objective

Use this skill to create a number of queries that are valid for the database and useful for answering business questions in the given context.

Each output query must include:
* The business question (context)
* Target user/users that would use the query
* Why is it useful?
* The full MS SQL implementation of the query 

The output will be used to test the realisticity of the sample data and functionality of the database. No performance optimizations (like Indexes, Views, or Triggers) are required at this stage. The Database Implementation is assumed to be complete and correct.

---

## Required Input Files

Read the following file:
* `outputs/05-db-implementation-G7.sql` (The database implementation SQL file)

If a previous query design already exists, also read:
* `outputs/07-query-design-G7.md`

Do not read any other unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* `outputs/05-db-implementation-G7.sql`

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

# Query Design Process

## Step 1: Parse Database Schema

- Read and analyze the SQL DDL file.
- Extract:
  - Tables and their purposes (e.g., users, bookings, spaces, etc.)
  - Primary keys and foreign keys
  - Relationships between tables
  - Constraints (CHECK, UNIQUE, etc.)
- Identify core entities:
  - Users
  - Spaces
  - Bookings
  - Approvals
  - Sessions
  - Maintenance Records
  - Facilities

---

## Step 2: Identify Business Workflows

From the schema, infer real-world workflows:

- Booking lifecycle:
  - User → Booking → Approval → Session → Completion
- Space management:
  - Space usage, facilities, availability
- Maintenance workflow:
  - Issue reporting → assignment → resolution
- Administrative oversight:
  - Approvals, monitoring, reporting

---

## Step 3: Define Target User Roles

Map queries to realistic system users.

For example:
- Student / Lecturer → booking spaces
- Facility Staff → maintenance tracking
- Facility Manager → approvals & utilization
- Department Administrator → reporting & analytics

Each query MUST specify its target user.

---

## Step 4: Formulate Business Questions

For each query:

- Create a realistic business question such as:
  - "Which rooms are most frequently used?"
  - "Are there any overlapping bookings?"
  - "What is the average maintenance resolution time?"
- Ensure:
  - Question reflects real-world usage
  - Question requires joining multiple tables where appropriate
  - Avoid trivial queries (e.g., simple SELECT *)

---

## Step 5: Design SQL Queries

- Write valid MS SQL (T-SQL) queries
- Ensure:
  - Correct joins based on foreign keys
  - Use of filters (WHERE), grouping (GROUP BY), aggregation (COUNT, AVG, etc.)
  - Use realistic conditions (dates, statuses, etc.)
- Do NOT include:
  - Indexes
  - Views
  - Triggers
  - Performance optimizations

---

## Step 6: Structure Output for Each Query

Each query MUST follow this format:

### Query Title

**Business Question:**  
Describe the real-world question being answered.

**Target Users:**  
List who would use this query.

**Why is it useful?**  
Explain the practical value of the query.

**SQL Implementation:**
```sql
-- Full working T-SQL query
```

---

**Important Rules:**

* Always follow the steps in order
* Prioritize correctness before scale
* Ensure the final script is clean, efficient, and reusable
* Solutions that have no target user or practical value are NOT acceptable

---

## Queries Target

The number of queries generated must be **20**, in which there have to be more than **5** different target users.

---

## Output Specification

Create or update:

`outputs/07-query-design-G7.md`

Do not omit any required section.

---

## Error Handling

If `outputs/05-db-implementation-G7.sql` do not exist:

* Stop execution.
* Report the missing file.
