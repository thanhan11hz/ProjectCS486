---
name: summarize-validate
description: Consolidate all intermediate analysis artifacts, validate consistency and completeness, and generate the final business requirement analysis document.
compatibility: opencode
---

# Summarization and Validation Skill

## Objective

Produce the final Business Requirement Analysis document by:

* Consolidating all validated analysis artifacts from previous stages.
* Eliminating duplicated or conflicting findings.
* Verifying consistency across business purpose, actors, entities, attributes, relationships, and business rules.
* Ensuring all identified business requirements are represented in the final model.
* Generating a single authoritative analysis document for subsequent ERD design.

This stage does not introduce new business concepts unless they are required to resolve obvious omissions discovered during validation.

---

## Required Input Files

Read the following files:

* `docs/business-analysis/understand-req.md`
* `docs/business-analysis/derive-entity-att.md`
* `docs/business-analysis/derive-relationship.md`
* `docs/business-analysis/derive-business-rule.md`

If an existing analysis already exists, also read:

* `outputs/01-business-req-analysis-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `docs/business-analysis/understand-req.md`
* `docs/business-analysis/derive-entity-att.md`
* `docs/business-analysis/derive-relationship.md`
* `docs/business-analysis/derive-business-rule.md`

If the file is missing:

* Stop execution.
* Report the missing prerequisite artifact.

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that all prerequisite artifacts exist.
2. Read the business requirement understanding artifact.
3. Read the approved entity and attribute definitions.
4. Read the approved relationship definitions.
5. Read the approved business rules.
6. Extract the final approved business purpose, actors, entities, attributes, relationships, and business rules.
7. Identify overlaps, inconsistencies, and missing references across artifacts.
8. Build a consolidated analysis inventory for validation and final document generation.

---

## Execution Process

Perform the following steps in order.

### Step 1 — Consolidate Analysis Results

Merge findings from:

* understand-req
* derive-entity-att
* derive-relationship
* derive-business-rule

Create unified collections of:

* Business purpose
* Actors
* Entities
* Attributes
* Relationships
* Relationship attributes
* Business rules
* Assumptions
* Ambiguities

Normalize naming and remove obvious duplicates.

---

### Step 2 — Validate Entity Definitions

For each entity:

Verify:

* Entity name is unique.
* Entity definition exists.
* Entity has sufficient identifying attributes.
* Entity is referenced consistently across artifacts.

Record any conflicts or omissions.

---

### Step 3 — Validate Attribute Definitions

For each attribute:

Verify:

* Attribute has a valid owner.
* Owner entity exists.
* Duplicate attributes are not defined multiple times.
* Attribute meaning is consistent across artifacts.

Identify:

* Orphan attributes.
* Duplicate definitions.
* Conflicting ownership assignments.

---

### Step 4 — Validate Relationship Definitions

For each relationship:

Verify:

* Both participating entities exist.
* Relationship meaning is clearly defined.
* Cardinality is specified.
* Participation constraints are consistent.

Identify:

* Missing cardinalities.
* Duplicate relationships.
* Conflicting relationship definitions.

---

### Step 5 — Validate Business Rule Consistency

For each business rule:

Verify that it is supported by:

* Entity definitions,
* Attributes,
* Relationships,
* or explicit requirements.

Identify:

* Unsupported rules.
* Duplicate rules.
* Contradictory rules.

---

### Step 6 — Validate Requirement Coverage

Review requirement statements from understand-req.

Verify that each significant requirement is represented through one or more of:

* Actor
* Entity
* Attribute
* Relationship
* Business Rule

Identify:

* Missing coverage.
* Partially covered requirements.
* Unused model elements.

---

### Step 7 — Resolve Duplications

Remove duplicated:

* Actors
* Entities
* Attributes
* Relationships
* Business rules

Retain the most complete and validated definition.

---

### Step 8 — Produce Final Business Analysis

Generate the final analysis document containing:

1. Business Purpose
2. Business Scope
3. Actors
4. Entity Catalog
5. Relationship Catalog
6. Business Rules
7. Assumptions
8. Ambiguities
9. Validation Summary

Use only validated findings.

Do not include intermediate reasoning from previous stages.

---

### Step 9 — Compare with Existing Analysis (Optional)

If `outputs/01-business-req-analysis-G7.md` already exists:

* Compare with the newly generated result.
* Preserve valid content when appropriate.
* Update sections that contain improved or corrected analysis.

Generate the final consolidated version.

---

## Important rules

### Scope Restrictions Rules

This stage is not responsible for:

* Redesign entities.
* Introduce new relationships.
* Create new business rules.
* Perform ERD design.
* Perform normalization.
* Generate relational schemas.

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

But they are to be seriously considered, since they can be very useful.

---

### Validation Rules

Validation focuses on consistency and completeness.

When inconsistencies are discovered:

* Report them.
* Prefer previously validated artifacts.
* Do not silently modify business meaning.

---

### Traceability Rules

Every major finding in the final document should be traceable to at least one previous artifact.

Do not create unsupported conclusions.

---

## Output Specification

Create or update:

`ouputs/01-business-req-analysis-G7.md`

The document must follow the template:

`.opencode/skills/business-analysis/summarize-validate/business-analysis-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

- [ ] All significant requirements are represented.
- [ ] All explicit business rules are captured.
- [ ] Every entity has been analyzed.
- [ ] Every relationship has been analyzed.
- [ ] Temporal constraints have been evaluated.
- [ ] Status attributes have been evaluated.
- [ ] Enumeration attributes have been evaluated.
- [ ] Relationship constraints have been evaluated.
- [ ] Real-world consistency constraints have been evaluated.
- [ ] Duplicate rules have been removed.
- [ ] No implementation-specific rules are included.
- [ ] Every derived rule can be traced back to the business model.
- [ ] The final analysis is suitable as input for conceptual ERD design.

---

## Error Handling

If :
* `docs/business-analysis/understand-req.md`
* `docs/business-analysis/derive-entity-att.md`
* `docs/business-analysis/derive-relationship.md`
* `docs/business-analysis/derive-business-rule.md` do not exist:

- Stop execution.
- Report the missing prerequisite artifact.