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
* `outputs/05-db-implementation-G7.sql` (The database implementation SQL file)

If a previous implementation of the SQL seed script already exists, also read:
* `outputs/06-sample-data-G7.sql`

Do not read any other unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:
* `outputs/05-db-implementation-G7.sql`

If the file is missing:
* Stop execution.
* Report the missing prerequisite artifact.

---

## Implementation Process

Follow these steps strictly in order. Do not skip or merge steps.

## Step 1: Reconstruct and Understand the Database Context

Before generating any sample data, fully understand the existing database design produced in previous steps. This includes:

* Identifying all **tables** in the schema
* Listing all **attributes** of each table
* Determining **primary keys**, **foreign keys**, and **candidate keys**
* Understanding **relationships** between tables (1–1, 1–N, N–M)
* Reviewing all **business rules and constraints**

---

## Step 2: Determine the Correct Data Insertion Order

Because of foreign key constraints, data must be inserted in a specific order to avoid violations. The correct order is determined by dependency relationships:

1. **Independent tables** (no foreign keys)
2. **Parent tables** (referenced by others)
3. **Child tables** (contain foreign keys)
4. **Bridge tables** (for many-to-many relationships)

For example, if `Bookings` references `Users`, then `Users` must be populated before `Bookings`.

---

## Step 3: Design Realistic Data Generation Strategies

The generated data should simulate real-world scenarios rather than using purely uniform random values. This involves:

* Using **meaningful value sets** (e.g., names, emails, categories)
* Generating **dates within realistic ranges**
* Applying **weighted distributions** (e.g., most users are active, fewer are inactive)
* Ensuring values follow **domain logic** (e.g., expected_participants are positive and within expected ranges)

For example:

* Status fields might follow a distribution like 70% “Active”, 20% “Pending”, 10% “Cancelled”
* Dates should reflect plausible timelines (e.g., booking dates within the past year)

---

## Step 4: Translate Business Rules into Data Constraints

All generated data must strictly comply with the business rules defined earlier. This requires translating abstract rules into concrete logic during insertion.

Examples:

* Only pending bookings can be **approved**
* A completed booking must have an **assigned staff member**
* Certain fields must be **non-null under specific conditions**

This may involve:

* Conditional logic during insertion
* Filtering invalid combinations
* Ensuring dependencies between attributes are respected

---

## Step 5: Apply SQL Server Randomization Techniques

To efficiently generate varied data, SQL Server’s built-in functions should be used:

* `NEWID()` → generates random unique identifiers
* `CHECKSUM(NEWID())` → produces pseudo-random integers
* `RAND()` → generates random floating-point numbers
* `DATEADD()` → creates randomized date values
* `ABS()` and modulo (%) → control numeric ranges

---

## Step 6: Use Set-Based Operations for Bulk Data Generation

Instead of inserting rows one by one, use **set-based operations** to generate large volumes of data efficiently.

Techniques include:

* `INSERT INTO ... SELECT`
* Using system tables such as `sys.objects` to generate row combinations
* `CROSS JOIN` to scale row counts exponentially
* `TOP (N)` to control dataset size

---

## Step 7: Maintain Referential Integrity Across Relationships

When inserting data into tables with foreign keys:

* Ensure all referenced values **exist in parent tables**
* Randomly assign valid foreign key values from existing records
* Preserve realistic relationship patterns (e.g., some users have many bookings, others have few)

This step guarantees that all relationships remain valid and meaningful within the dataset.

---

## Step 8: Include Edge Cases and Exceptional Scenarios

In addition to normal data, the dataset should include edge cases to test system robustness:

* **NULL values** (where allowed)
* **Boundary values** (e.g., minimum and maximum limits)
* **Rare conditions** (e.g., cancelled bookings, inactive users)
* **Constraint edge cases** to verify validation logic

---

## Step 9: Compile a Complete and Executable SQL Script

Finally, all data generation logic should be combined into a single, clean SQL script that:

* Inserts data in the correct order
* Uses efficient bulk operations
* Respects all constraints and business rules
* Can generate large datasets (thousands of rows)

Optional enhancements include:

* Wrapping operations in **transactions**
* Temporarily disabling and re-enabling constraints for performance (if appropriate)
* Adding comments for clarity and maintainability

The final script should be fully executable and capable of populating the database reliably for testing and evaluation purposes.

---

**Important Rules:**

* Always follow the steps in order
* Never skip validation or business rules
* Prioritize correctness before scale
* Ensure the final script is clean, efficient, and reusable

---

## Output Specification

Create or update:

`outputs/06-sample-data-G7.sql`

Do not omit any required section.

---

## Error Handling

If `outputs/05-db-implementation-G7.sql` do not exist:

* Stop execution.
* Report the missing file.