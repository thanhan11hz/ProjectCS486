---

name: design-validation
description: validate whether the relational schema correctly represents the ERD, satisfies business rules, and uses appropriate keys, relationships, and constraints.
compatibility: opencode
-----------------------

# Required Input Files

IMPORTANT: Do not read unrelated files unless explicitly requested.

Read the business requirements from:

* `outputs/01-business-req-analysis-G7.md`

Read the ERD design from:

* `outputs/02-erd-design-G7.md`

Read the relational schema design from:

* `outputs/03-logical-design-G7.md`

---

# Validation Criteria

## 1. Entity Coverage

Verify that every entity defined in the ERD is represented in the relational schema.

### Verify

* All entities appear as relations/tables.
* No required entity is missing.
* No unnecessary tables have been introduced without justification.

### Example

**ERD**

* Student
* Course
* Instructor

**Schema**

```text
Student(...)
Course(...)
Instructor(...)
```

Result:

* PASS if all entities are represented.

---

## 2. Attribute Coverage

Verify that all attributes defined in the ERD are included in the corresponding relations.

### Verify

* All simple attributes are present.
* Composite attributes are appropriately decomposed if required.
* Derived attributes are handled consistently.
* No required attributes are missing.

### Example

**ERD**

```text
Student(StudentID, Name, Email)
```

**Schema**

```text
Student(StudentID, Name)
```

Issue:

* Email attribute is missing.

---

## 3. Key Validation

Verify that keys are correctly identified and implemented.

### Verify

* Primary keys uniquely identify each tuple.
* Candidate keys are preserved where appropriate.
* Alternate keys use UNIQUE constraints when required.
* Composite keys are correctly defined.
* Weak entity keys are correctly implemented.

### Example

```text
Student(
    StudentID,
    Name,
    Email
)
```

Primary Key:

```text
StudentID
```

Result:

* Verify that every row can be uniquely identified.

---

## 4. Relationship Coverage

Verify that every relationship in the ERD is represented in the relational schema.

### Verify

* All relationships appear in the schema.
* Relationship tables exist when required.
* Foreign keys correctly represent relationships.

### Example

**ERD**

```text
Student enrolls in Course
```

**Schema**

```text
Enrollment(
    StudentID,
    CourseID
)
```

Result:

* Relationship correctly represented.

---

## 5. Weak Entity Validation

Verify that weak entities are correctly transformed into relations.

### Verify

* Weak entities exist as relations.
* Identifying relationships are preserved.
* The primary key includes the owner's key when required.
* Foreign keys correctly reference the owning entity.

### Example

```text
Dependent(
    EmployeeID,
    DependentName
)
```

Primary Key:

```text
(EmployeeID, DependentName)
```

Result:

* Weak entity correctly implemented.

---

## 6. Cardinality Validation

Verify that relationship cardinalities from the ERD are preserved.

### Verify

#### One-to-One (1:1)

* Implemented using foreign keys and uniqueness constraints where necessary.

#### One-to-Many (1:N)

* Foreign key exists on the many side.

#### Many-to-Many (M:N)

* Implemented using an associative relation.

### Example

**Requirement**

```text
One Department has many Employees
```

**Schema**

```text
Employee(
    EmpID,
    DeptID
)
```

Result:

* Foreign key correctly models the relationship.

---

## 7. Participation Constraint Validation

Verify that mandatory and optional participation constraints are enforced.

### Verify

* Mandatory participation uses NOT NULL foreign keys.
* Optional participation allows NULL values where appropriate.

### Example

```text
Employee(
    EmpID,
    DeptID NOT NULL
)
```

Result:

* Every employee must belong to a department.

---

## 8. Constraint Validation

Verify that schema constraints correctly enforce the database design.

### Verify

* PRIMARY KEY constraints
* FOREIGN KEY constraints
* UNIQUE constraints
* NOT NULL constraints
* CHECK constraints
* DEFAULT constraints

### Identify

* Missing constraints.
* Incorrect constraints.
* Unnecessary constraints.

---

## 9. Functional Dependency Validation

Where functional dependencies can be inferred from the ERD or requirements, verify that they are preserved.

### Verify

* Attributes depend on the appropriate key.
* Partial dependencies are avoided.
* Transitive dependencies are minimized.
* Dependencies are preserved after transformation.

### Example

```text
StudentID → Name, Major
```

Result:

* Non-key attributes depend on the primary key.

---

## 10. Normalization Check

Verify that redundancy is minimized and normalization goals are satisfied.

### Verify

* First Normal Form (1NF)
* Second Normal Form (2NF)
* Third Normal Form (3NF)

If applicable:

* Boyce-Codd Normal Form (BCNF)

### Identify

* Partial dependencies.
* Transitive dependencies.
* Update anomalies.
* Insertion anomalies.
* Deletion anomalies.

### Example

Poor Design:

```text
Student(
    StudentID,
    StudentName,
    CourseID,
    CourseName
)
```

Problem:

```text
CourseID → CourseName
```

Result:

* Indicates a normalization issue.

---

## 11. Referential Integrity Validation

Verify that foreign key relationships are valid.

### Verify

* Every foreign key references a valid primary key or candidate key.
* Foreign key relationships are consistent.
* Referential integrity is maintained.

### Example

```text
Enrollment.StudentID
    → Student.StudentID

Enrollment.CourseID
    → Course.CourseID
```

Result:

* Referential integrity preserved.

---

## 12. Business Rule Enforcement

Verify whether business rules can be enforced using table-level database constraints.

### Supported Constraint Types

* PRIMARY KEY
* FOREIGN KEY
* UNIQUE
* NOT NULL
* CHECK
* DEFAULT

### Evaluation Process

For each business rule:

1. State the rule.
2. Determine whether it can be enforced using table-level constraints.
3. Identify the required constraint(s).
4. Verify that the schema contains those constraints.
5. Report any missing enforcement.

### Examples

Rule:

```text
Student age must be greater than 17.
```

Constraint:

```sql
CHECK (Age > 17)
```

Rule:

```text
Grade must be between 0 and 100.
```

Constraint:

```sql
CHECK (Grade BETWEEN 0 AND 100)
```

### Notes

Some business rules cannot be enforced using standard table constraints alone.

Examples:

* Maximum number of students enrolled in a course.
* Total enrollments per student.
* Aggregate calculations across multiple rows.
* Complex cross-table validations.

Such rules should be documented as requiring implementation outside the schema (e.g., application logic).

---

# Quick Validation Checklist

| Check                     | Validation Question                                        |
| ------------------------- | ---------------------------------------------------------- |
| Entity Coverage           | Are all entities represented?                              |
| Attribute Coverage        | Are all attributes included?                               |
| Key Validation            | Are primary, candidate, and alternate keys correct?        |
| Relationship Coverage     | Are all relationships modeled?                             |
| Weak Entity Validation    | Are weak entities correctly implemented?                   |
| Cardinality Validation    | Are 1:1, 1:N, and M:N relationships represented correctly? |
| Participation Constraints | Are mandatory relationships enforced?                      |
| Constraint Validation     | Are appropriate constraints defined?                       |
| Functional Dependencies   | Are dependencies preserved correctly?                      |
| Normalization             | Is redundancy minimized?                                   |
| Referential Integrity     | Are foreign keys valid?                                    |
| Business Rules            | Can business rules be enforced?                            |

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

1. The relational schema correctly represents the ERD.
2. Relationships and cardinalities are preserved.
3. Keys are appropriately implemented.
4. Constraints are correctly defined.
5. Business rules are adequately enforced.
6. The schema is suitable for implementation.

---

## Output Specification

Create or update:

`outputs/04-design-validation-G7.md`

The document must follow the template:

`.opencode/skills/design-validation/design-validation-template.md`

Do not omit any required section.


---

# Recommended Evaluation Process

1. Identify all entities from the ERD.
2. Verify corresponding relations exist.
3. Check attribute completeness.
4. Validate keys.
5. Validate relationships.
6. Validate weak entities.
7. Verify cardinalities.
8. Verify participation constraints.
9. Check schema constraints.
10. Validate functional dependencies.
11. Assess normalization.
12. Verify referential integrity.
13. Evaluate business rule enforcement.
14. Produce the final verdict.
