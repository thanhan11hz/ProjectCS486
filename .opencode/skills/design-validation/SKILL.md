---

name: design-validation
description: validate whether the relational schema correctly represents the ERD, satisfies business rules, and uses appropriate keys, relationships, and constraints.
compatibility: opencode
-----------------------

# Validate Compatibility Between ERD And Relational Schema

IMPORTANT: Do not read unrelated files unless explicitly requested.

Read the ERD design from:

* `outputs/02-erd-design-G7.md`

Read the relational schema design from:

* `outputs/03-logical-design-G7.md`

Read the mapping rules from:

* `.opencode/skills/logical-design/SKILL.md`

---


## 1. Entity Coverage

Verify:

* All entities in ERD appear as relation in the relational schema.
* No required entity is missing.
* No unnecessary relations have been introduced without justification.
* Primary key of each table is correctly defined.

Document the correct and incorrect mapping between entities and relations.

For each relation representing an entity, verify all attributes are present. Record attributes not included

---

## 2. Relationship Coverage 

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
* Subtypes and supertypes
* Derived attributes

Document correct and incorrect assumptions or design decisions.
Document the correct and incorrect uses of mapping rules.

---

## 4. Constraint Validation


To verify whether business rules can be enforced using table-level database constraints, only the following constraint types are supported:

* Domain constraints
* PRIMARY KEY constraints
* FOREIGN KEY constraints
* Constraints on NULL values
* Constraints on UNIQUE values
* Entity Integrity constraints
* Referential Integrity constraints

Note: do not count violations of business rules that cannot be enforced using table-level database constraints as failures.

### 4.1 Domain Constraints

For each attribute of each relation, verify:

* Correct value range is specified.
* Fixed set of values are correctly enforced in case of enumerated values
* NULL/NOT NULL constraints are correctly identified.
* UNIQUE constraints are correctly identified

Record incorrect constraints.

### 4.2 Entity Integrity Constraints

For each relation, verify:

* Every primary key attribute is defined as NOT NULL.
* Every primary key attribute is defined as UNIQUE.
* No component of a composite primary key allows NULL values.
* Each relation has a clearly identified primary key.

Record violations of entity integrity.

### 4.3 Referential Integrity Constraints

For each foreign key, verify:

* The referenced relation and referenced key exist.
* The foreign key and referenced key have compatible domains and data types.
* No foreign key references a non-key attribute 

Record violations of referential integrity.

---

# Validate Business Rule Satisfaction

IMPORTANT: Do not read unrelated files unless explicitly requested.

Read the business requirements from:

* `outputs/01-business-req-analysis-G7.md`

Read the relational schema design from:

* `outputs/03-logical-design-G7.md`

---

To verify whether business rules can be enforced using table-level database constraints, only the following constraint types are supported:

* Domain constraints
* PRIMARY KEY constraints
* FOREIGN KEY constraints
* Constraints on NULL values
* Constraints on UNIQUE values
* Entity Integrity constraints
* Referential Integrity constraints

Note: do not count violations of business rules that cannot be enforced using table-level database constraints as failures.

For each business rule:

1. State the rule.
2. Determine whether it can be enforced using table-level constraints.
3. Identify the required constraint(s).
4. Verify that the schema contains those constraints.
5. Report any missing enforcement.

---

# Required Output

## Summary

Provide:

* Total issues found.
* Critical issues.
* Minor issues.

---

## Detailed Findings

For each validation criterion:

* PASS or FAIL
* Explanation
* Evidence from ERD and schema
* Recommended correction

---

## Final Verdict

State whether:

1. Relational schema is compatibly mapped from the ERD
2. Relational schema satisfied all business rules that an be enforced using table-level database constraints
---

## Output Specification

Create or update:

`outputs/04-design-validation-G7.md`

The document must follow the template. Read the template from:

`.opencode/skills/design-validation/design-validation-template.md`

Do not omit any required section.