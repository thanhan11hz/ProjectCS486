---
description: Classify extracted concepts into actors, business objects, business events, transactions, attributes, statuses, enumerations, and other domain concepts.
---

Execute:

1. Load:
   `.opencode/skills/business-analysis/classify-concept/SKILL.md`

2. Execute the skill.

3. Generate or update:
   `docs/business-analysis/classify-concept.md`

4. Stop.

Rules:

* Do not load unrelated skills.
* Execute only the specified skill.
* If a prerequisite artifact is missing, report it and stop.
* Update only files owned by this stage.
* Do not modify artifacts owned by other stages.