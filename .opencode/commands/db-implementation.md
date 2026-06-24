---
description: Transform validated logical database schema into executable Microsoft SQL Server DDL scripts no seed data.
---

Execute:

1. Load:
   `.opencode/skills/db-implementation/SKILL.md`

2. Execute the skill. 

3. Generate or update:
   `outputs/05-db-implementation-G7.sql`

4. Stop.

Rules:
* If the output file has already exist, validate it again and update the SQL file with all the rule in the skill and update the file, do not skip this step.
* Do not load unrelated skills.
* Execute only the specified skill.
* If a prerequisite artifact is missing, report it and stop.
* Update only files owned by this stage.
* Do not modify artifacts owned by other stages.