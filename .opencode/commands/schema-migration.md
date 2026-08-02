---
description: Generate SQL migration scripts to evolve the old database schema while preserving existing data whenever possible.
---

Execute:

1. Load:
   `.opencode/skills/schema-migration/SKILL.md`

2. Execute the skill.

3. Generate or update:
   `outputs/10-schema-migration-G7.sql`

4. Stop.

Rules:

* Do not load unrelated skills.
* Execute only the specified skill.
* If a prerequisite artifact is missing, report it and stop.
* Update only files owned by this stage.
* Do not modify artifacts owned by other stages.