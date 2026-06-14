---
description: Execute a database design stage or the complete CS486 pipeline
---

The command argument has already been provided.

Interpret `$ARGUMENTS` as the selected stage.

Do not ask the user which stage to execute.
Do not request confirmation.
Execute immediately.

Stage aliases:

* 1 or business-analysis
* 2 or conceptual-design
* 3 or logical-design
* 4 or design-validation
* 5 or database-implementation
* 6 or sample-data
* 7 or query-design
* all

Execution:

When STAGE = 1 or business-analysis:

* Read `.opencode/skills/business-analysis/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/01-business-req-analysis.md`
* Stop

When STAGE = 2 or conceptual-design:

* Read `.opencode/skills/conceptual-design/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/02-erd-design.md`
* Stop

When STAGE = 3 or logical-design:

* Read `.opencode/skills/logical-design/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/03-logical-design.md`
* Stop

When STAGE = 4 or design-validation:

* Read `.opencode/skills/design-validation/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/04-design-validation.md`
* Stop

When STAGE = 5 or database-implementation:

* Read `.opencode/skills/database-implementation/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/05-db-definition.sql`
* Stop

When STAGE = 6 or sample-data:

* Read `.opencode/skills/sample-data/SKILL.md`
* Execute the skill
* Generate or update:
  `docs/06-sample-data.sql`
* Stop

When STAGE = all:

Execute the following stages in order:

1. business-analysis
2. conceptual-design
3. logical-design
4. design-validation
5. database-implementation
6. sample-data
7. query-design

Generate or update all corresponding output files.

Additional rules:

* Execute only the selected stage unless STAGE = all.
* Do not load unrelated skills.
* Each skill is responsible for locating business requirements and prerequisite artifacts.
* If a prerequisite artifact is missing, report the missing artifact and stop.
* Update only the files owned by the executed stage.