---
name: design-validation
description: Validate whether the relational schema correctly represents the ERD, satisfies business rules, and uses appropriate keys, relationships, and constraints.
compatibility: opencode
---

# Design Validation Skill

## Objective

Validate whether the relational schema:

- Correctly represents the ERD.
- Correctly applies ER-to-relational mapping rules.
- Satisfies all enforceable business rules.
- Uses appropriate keys, relationships, and integrity constraints.

---

## Required Input Files

Read the following files:

* `outputs/01-business-req-analysis-G7.md`
* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`

Read the mapping rules from:

* `.opencode/skills/logical-design/SKILL.md`

If an existing analysis already exists, also read:

* `outputs/04-design-validation-G7.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/01-business-req-analysis-G7.md`
* `outputs/02-erd-design-G7.md`
* `outputs/03-logical-design-G7.md`

If the file is missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Discovery Process

1. Read the business requirement analysis.
2. Read the conceptual ERD.
3. Read the logical design.
4. Load the ER-to-relational mapping rules.
5. Validate entity mapping.
6. Validate relationship mapping.
7. Validate special ER construct mapping.
8. Validate integrity constraints.
9. Validate business rule enforceability.
10. Generate the validation report.

---

## Design Validation Rules

### 1. Entity Coverage Validation

Verify:

* All entities in ERD appear as relation in the relational schema.
* No required entity is missing.
* No unnecessary relations have been introduced without justification.
* Primary key of each table is correctly defined.

Document the correct and incorrect mapping between entities and relations.

For each relation representing an entity, verify all attributes are present. Record attributes not included

---

### 2. Relationship Coverage Validation

For each conceptual relationship, verify:

* Verify it is represented through foreign key references or associative relations.
* Cardinality is correctly determined.
* Participation constraints are correctly determined.

Document relationships that are correctly and incorrectly handled.
Document relationships that are not handled. 

For each relation representing a relationship, verify:

* Approriate foreign keys are included.
* Primary key is correctly defined.
* Correct and sufficient relationship attributes are included.
* Referenced relations are correctly determined.

Document correct and incorrect relations that represent relationships.

--- 

## 3. Special Construct Validation

Verify all special ER constructs are correctly handled. The special constructs include:

* Composite attributes
* Multivalued attributes
* Weak entities
* Recursive relationships
* N-ary relationships
* Derived attributes

Document correct and incorrect assumptions or design decisions.
Document the correct and incorrect uses of mapping rules.

---

## 4. Constraint Validation


To verify whether business rules can be enforced using logical-schema-level database constraints, only the following constraint types are supported:

* Domain constraints
* Constraints on NULL/NOT NULL values
* Key constraints
* Entity Integrity constraints
* Referential Integrity constraints

Note: do not count violations of business rules that cannot be enforced using logical-schema-level database constraints as failures.

### 4.1 Domain Constraints

For each attribute of each relation, verify:

* Correct value range is specified.
* Fixed set of values are correctly enforced in case of enumerated values
* NULL/NOT NULL constraints are correctly identified.
* UNIQUE constraints are correctly identified

Record incorrect constraints.

## 4.2 Key Constraints

For each relation, verify:

* Candidate keys are correctly identified.
* Each candidate key satisfies uniqueness requirements.
* Primary key selection is appropriate among candidate keys.
* No non-key attribute is incorrectly defined as a key.
* Composite keys contain the correct set of attributes.
* Unique constraints are correctly applied to alternate keys.

Record key constraint violations.

---

### 4.3 Entity Integrity Constraints

For each relation, verify:

* Every primary key attribute is defined as NOT NULL.
* Every primary key attribute is defined as UNIQUE.
* No component of a composite primary key allows NULL values.
* Each relation has a clearly identified primary key.

Record violations of entity integrity.

### 4.4 Referential Integrity Constraints

For each foreign key, verify:

* The referenced relation and referenced key exist.
* The foreign key and referenced key have compatible domains and data types.
* No foreign key references a non-key attribute 

Record violations of referential integrity.

---

## 4.5 NULL Constraints

For each attribute, verify:

* Mandatory attributes are defined as NOT NULL.
* Optional attributes allow NULL values.
* Primary key attributes cannot contain NULL values.
* Foreign key attributes allow or restrict NULL values according to the relationship optionality.
* NULL constraints do not conflict with other constraints (e.g., NOT NULL combined incorrectly with SET NULL referential actions).

Record incorrect NULL constraints.

---

## 4.6 Constraint Consistency Validation

For each relation schema, verify:

* Constraints do not conflict with each other.
* Primary keys, foreign keys, and unique constraints are defined consistently.
* Foreign key constraints do not violate entity integrity of referenced relations.
* Domain restrictions do not prevent valid relational operations.
* All declared constraints correspond to the intended relational model.

Record inconsistent or conflicting constraints.

---

# Business Rule Validation

IMPORTANT: Do not read unrelated files unless explicitly requested.

Read the business requirements from:

* `outputs/01-business-req-analysis-G7.md`

Read the relational schema design from:

* `outputs/03-logical-design-G7.md`


Validation is performed on the relational schema, **not SQL**.

Assume only the following mechanisms:

- Attribute-based CHECK constraints
- NULL/NOT NULL constraints
- Key constraints
- Entity Integrity constraints
- Referential Integrity constraints

Do **not** assume:

- Triggers
- Stored procedures
- Assertions
- Exclusion constraints
- Tuple-based CHECK constraints
- Application logic

Mark a rule as **Not Enforceable** if it requires:

- Validation involving another table beyond foreign keys.
- Validation involving multiple attributes of a tuple.
- Validation involving multiple rows.
- Workflow or state transition logic.
- Historical record preservation.
- Automatic updates.
- Conditional existence of related records.
- User role or permission validation.

# Execution process

### Step 1 — Validate Entity Coverage

Perform Entity Coverage Validation.

Record:

- PASS / FAIL
- Evidence
- Recommended corrections

---

### Step 2 — Validate Relationship Coverage

Perform Relationship Coverage Validation.

Record:

- PASS / FAIL
- Evidence
- Recommended corrections

---

### Step 3 — Validate Special Constructs

Perform Special Construct Validation.

Record:

- PASS / FAIL
- Evidence
- Recommended corrections

---

### Step 4 — Validate Constraints

Perform:

- Domain Constraint Validation
- Entity Integrity Validation
- Referential Integrity Validation

Record all violations.

---

### Step 5 — Validate Business Rule Satisfaction

For each business rule:

1. Determine whether it is enforceable.
2. Identify supporting constraint types.
3. Explain the reasoning.
4. If not enforceable, identify the required mechanism.
5. Do not mark a rule as enforceable merely because the schema can store the data.

---

### Step 6 — Generate Validation Report

Produce:

#### Summary

- Total issues found
- Critical issues
- Minor issues

#### Detailed Findings

For every validation criterion include:

- PASS or FAIL
- Explanation
- Evidence from the ERD and relational schema
- Recommended correction

#### Final Verdict

State whether:

1. The relational schema is correctly mapped from the ERD.
2. The relational schema satisfies all enforceable business rules using logical-schema-level database constraints.

---

## Output Requirements

IMPORTANT: Do not mark a rule as fail if it is not enforceable. 

For each business rule:

1. State whether it is enforceable using only the allowed constraint types.
2. Identify the specific constraint types that support the rule.
3. Explain why the rule is enforceable or not enforceable.
4. If not enforceable, describe what additional mechanism would be required (e.g., trigger, application logic, workflow logic).

---

## Important rules

### Scope Restrictions Rules

This stage is not responsible for:

- SQL implementation
- Sample data validation
- Query validation
- Performance optimization
- Other implementation-stage activities

Those activities belong to later stages.

---

### Validation Consistency Rule

The Business Requirement Analysis and Conceptual ERD remain the authoritative sources.

Do not introduce new entities, relationships, or business rules during validation.

---

## Output Specification

Create or update:

`outputs/04-design-validation-G7.md`

The document must follow the template. Read the template from:

`.opencode/skills/design-validation/design-validation-template.md`

Do not omit any required section.

## Validation checklist


Before saving:

- Every entity has been validated.
- Every relationship has been validated.
- Every special ER construct has been validated.
- Every applicable constraint has been validated.
- Every enforceable business rule has been evaluated.
- Every finding includes supporting evidence.
- Every finding includes PASS or FAIL.
- The final verdict is provided.

---

## Error handling

If any required input file is missing:

- Stop execution.
- Report the missing prerequisite artifact.

If inconsistencies are found:

- Record the inconsistency.
- Recommend the appropriate correction.

If a business rule cannot be enforced using logical-schema-level constraints:

- Mark it as **Not Enforceable**.
- Recommend the additional mechanism required.