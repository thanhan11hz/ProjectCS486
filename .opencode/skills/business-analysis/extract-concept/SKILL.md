---
name: extract-concept
description: Extract all business concepts, terms, and domain objects explicitly or implicitly mentioned in the requirements without classification or interpretation..
compatibility: opencode
---

# Concept Extraction Skill

## Objective

Analyze the business requirement document and extract all business concepts, terms, domain objects, statuses, activities, roles, resources, events, policies, and other meaningful business vocabulary explicitly or implicitly mentioned in the requirements.

The objective of this stage is to build a complete concept inventory that can be used by later stages such as entity identification, relationship analysis, business rule extraction, and database design.

This stage focuses on concept discovery only.

Do not classify concepts as entities, attributes, relationships, business rules, or database structures.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`

If an existing analysis already exists, also read:

* `docs/business-analysis/concept-extract.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that `req/business-requirement.md` exists.
2. Read the requirement document completely before performing analysis.
3. Identify all business objectives, users, activities, constraints, and data requirements.
4. If an existing analysis document exists, use it only as reference and regenerate the analysis from the business requirements.
5. Do not assume missing requirements unless necessary.

---

## Execution Process

Perform the following steps in order.

## Step 1: Extract Explicit Concepts

Extract business-relevant concepts explicitly mentioned in the requirement.

### Include

* Roles and actors
* Organizational units
* Physical resources
* Business objects
* Activities or processes
* Events
* Status values
* Policies or constraints

### Exclude

### Exclude

* Attributes of another concept
* Data fields
* Property names
* Identifiers
* Temporal fields
* Measurement fields
* Contact information
* Individual values
* Descriptive adjectives
* General language that does not represent a business concep

### Rules

* Record concepts exactly as written whenever possible.
* Do not rename concepts during extraction.
* Record supporting requirement evidence for each concept.
* Do not infer new concepts in this step.

---

## Step 2: Normalize Concepts

Normalize equivalent concepts that clearly refer to the same business meaning.

### Allow Normalization Only When

1. Singular and plural variations exist.
2. One term is an abbreviated form of another.
3. The requirement explicitly uses alternative references for the same concept.
4. One term is a shortened reference to a previously defined concept.

### Do Not Normalize When

* The concepts may represent different business meanings.
* The equivalence is based only on semantic similarity.
* The equivalence requires business interpretation.

### Rules

* Retain the most complete business term as the canonical concept.
* Record all aliases separately.
* Provide justification for every normalization decision.
* Each alias may map to only one canonical concept.
* Do not create bidirectional mappings.
* A concept cannot simultaneously be a canonical concept and an alias of another concept.

---

## Step 3: Categorize Concepts

Assign each normalized concept to exactly one category.

### Category Priority Order

Apply the first matching category.

1. Role / Actor
2. Organizational Unit
3. Physical Resource
4. Business Object
5. Activity / Process
6. Event
7. Status
8. Policy / Constraint
9. Other

### Pre-Categorization Filter

Before assigning categories, remove concepts that represent:

* Attributes
* Data fields
* Property names
* Derived reports
* Query results
* Aggregated views

should not be categorized unless they are independently managed business concepts.

### Rules

* Each concept must appear in exactly one category.
* If multiple categories seem applicable, use the first matching category in the priority order.
* Categorization is for analysis purposes only.
* Categories must not be interpreted as database design decisions.

---

## Step 4: Extract Strongly-Supported Implicit Concepts

Identify concepts that are not explicitly named but are strongly implied by the requirement.

### Extract an Implicit Concept Only If All Conditions Are True

1. The concept is necessary to connect two or more explicit requirements.
2. The concept is supported by at least two independent requirement statements.
3. The concept has observable business behavior or lifecycle.
4. The concept is not merely a synonym of an explicit concept.

### Rules

* Provide supporting evidence for every implicit concept.
* Explain why the concept is implied.
* Do not introduce speculative concepts.
* Do not infer future features or implementation details.

### Additional Guidance

Implicit concepts commonly emerge when multiple requirement statements collectively describe:

* A lifecycle
* A business state transition
* A business decision
* A business interaction
* A managed activity

Examples:

A requirement describing:

* approval status
* approval time
* approver
* rejection reason

may imply an Approval Decision concept.

A requirement describing:

* actual start time
* actual end time
* check in
* completion

may imply a Usage Session concept.

Do not reject an implicit concept merely because a related activity is explicitly mentioned.

---

## Step 5: Identify Ambiguous Concepts

Identify concepts whose business meaning is unclear or may reasonably support multiple interpretations.

### Mark a Concept as Ambiguous Only If

1. The requirement does not define its scope.
2. Multiple interpretations are possible.
3. The concept appears in more than one business context.
4. The concept could represent different business abstractions (entity, process, event, status, etc.).

### Rules

* Describe the ambiguity.
* Provide supporting requirement evidence.
* Do not resolve the ambiguity.
* Do not create assumptions.

---

## Global Rules

1. Use only information supported by the requirement.
2. Clearly distinguish explicit concepts from implicit concepts.
3. Do not introduce implementation concepts.
4. Do not introduce database-specific concepts.
5. Do not create assumptions unless explicitly requested.
6. Every extracted concept must be traceable to requirement evidence.
7. Every implicit concept must satisfy all extraction criteria.
8. Every ambiguity must be supported by requirement evidence.
9. If evidence is insufficient, do not extract the concept.
10. When uncertain, prefer omission over speculation.
11. A concept must represent a business meaning, not merely a stored property.
12. Prefer business concepts over data elements.
---

## Deliverable

Produce the following sections in order:

1. Explicit Concepts
2. Normalized Concepts
3. Categorized Concepts
4. Strongly-Supported Implicit Concepts
5. Ambiguous Concepts

Each section must follow the required output format and include supporting evidence where applicable.

---

## Important rules

### Scope Restrictions Rules

This stage is not responsible for:

* Entity identification
* Attribute identification
* Relationship identification
* Cardinality analysis
* Business rule extraction
* ERD design
* Relational schema design
* Database implementation

Those activities belong to later stages.

---

### Example Usage Rules

Examples used in this skill are illustrative only.

Do not reuse example entities, actors, activities, or business rules from the examples.

Always derive results exclusively from the provided business requirements.

---

### Concept Extraction Rules

Extract concepts before interpretation.

Prefer completeness over early classification.

A concept may later become:

* Entity
* Attribute
* Relationship
* Enumeration value
* Business rule term

Do not decide that in this stage.

Keep business terminology as close as possible to the original requirements.

---

## Output Specification

Create or update:

`docs/business-analysis/extract-concept.md`

The document must follow the template:

`.opencode/skills/business-analysis/extract-concept-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

* All major business terms have been extracted.
* Roles and actors are identified.
* Activities and events are identified.
* Status values are identified.
* Resources and business objects are identified.
* Duplicate concepts are normalized where appropriate.
* Ambiguous concepts are documented.
* No entities are proposed.
* No relationships are proposed.
* No business rules are extracted.
* No database structures are proposed.
* Attribute-like terms have been excluded.
* Contact information has not been extracted as concepts.
* Temporal fields have not been extracted as concepts.
* Normalization mappings are one-directional.
* At least one review of possible implicit concepts has been performed.

---

## Error Handling

If `req/business-requirement.md` does not exist:

* Stop execution.
* Report the missing file.
* Do not fabricate requirements.

If the requirement document is incomplete:

* Continue analysis using reasonable assumptions.
* Clearly document all assumptions and unresolved questions.

If contradictions are found:

* Record the conflict.
* Explain alternative interpretations.
* Select the most reasonable interpretation and justify it.