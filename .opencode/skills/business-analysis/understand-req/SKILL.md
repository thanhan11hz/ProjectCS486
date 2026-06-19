---
name: understand-req
description: Understand business requirements and generate the requirement understanding artifact.
compatibility: opencode
---

# Business Requirement Understanding Skill

## Objective

Analyze the business requirement document and produce a requirement understanding artifact containing:

* Problem Statement
* Business Purpose
* Expected Business Outcomes
* Actors
* Actor Responsibilities
* Major Business Activities

This stage focuses only on understanding the business context and scope.

Do not identify entities, attributes, relationships, or business rules in this stage.

---

## Required Input Files

Read the following files:

* `req/business-requirement.md`

If an existing analysis already exists, also read:

* `docs/business-analysis/understand-req.md`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

This is the first stage of the business analysis pipeline.

No prerequisite artifacts are required.

---

## Discovery Process

1. Verify that `req/business-requirement.md` exists.
2. Read the requirement document completely before performing analysis.
3. Identify all business objectives, users, activities, constraints, and data requirements.
4. If an existing analysis document exists, use it only as reference and regenerate the analysis from the business requirements.
5. Do not assume missing requirements unless necessary.
6. Identify unclear, incomplete, or conflicting requirements.
7. Record ambiguities, assumptions, and open questions separately from the main analysis.

---

## Execution Process

Perform the following steps in order.

### Step 1: Understand the Business Context

### Domain

Extract the organization responsible for the business process.

### Current Situation

List the current process described in the requirement.

### Problems and Pain Points

List only problems explicitly mentioned.

### Need for the Proposed System

List only objectives explicitly mentioned.

Example:

Hotel Scenario

Current Situation:
A hotel manages room reservations using spreadsheets.

Problems:
- Double booking occurs frequently.
- Room availability is difficult to track.
- Reservation history is fragmented.

Business Need:
Develop a centralized reservation management system.

---

### Step 2: Identify Business Purpose

Extract business objectives explicitly stated in the requirement.

Rules:
- Use only information directly supported by the requirement.
- Do not infer strategic goals, benefits, or motivations.
- If an objective is not explicitly stated, do not invent one.

### Primary purpose

List main goal of the proposed system

### Supported purpose

List additional objectives if applicable

Example:

Hospital Scenario

Purpose:
Manage patient admissions, treatments, and discharge records.

Expected Value:
- Reduce manual paperwork.
- Improve patient tracking.
- Improve access to medical history.

---

### Step 3: Identify Expected Outcomes

### Operational Outcomes

List expected operational improvements

### Business Outcomes

List expected business benefits

### System Capabilities

List desired capabilities of the future system

Example:

Hotel Scenario

Expected Outcomes:
- Prevent room reservation conflicts.
- Track room occupancy status.
- Maintain reservation history.
- Improve front desk operations.

---

### Step 4: Identify Actors

Extract all users, roles, departments, and external parties mentioned that manage, design and use this system in the requirements.

For each actor record:

* Name
* Description
* Responsibilities
* Interactions with the system

Example:

Hospital Scenario

Actor:
Doctor

Description:
Medical professional responsible for patient care.

Responsibilities:
- View patient records.
- Record diagnoses.
- Prescribe treatments.

Interactions:
- Access patient information.
- Create treatment records.

---

### Step 5: Identify Major Business Activities

List major business activities described in the requirements.

Examples:

Hotel Scenario

Major Business Activities:
- Room Reservation
- Guest Check-In
- Guest Check-Out
- Room Maintenance
- Payment Processing

Do not identify entities, attributes, relationships, or business rules in this step.

---

### Step 6: Create Scope Summary

Summarize the functional boundary of the requirement.

#### In Scope

Include:

* Functions explicitly described in the requirements
* Responsibilities the system is expected to support
* Activities that are clearly part of the business problem

#### Out of Scope

Include:

* Functions explicitly excluded by the requirements
* Activities not mentioned but commonly associated with similar systems
* Areas that would require assumptions beyond the available requirements

Do not invent future features.

### Step 7: Analyze Ambiguities

Identify requirements that may have multiple valid interpretations.

For each ambiguity:

1. Record the requirement statement.
2. Explain why the statement is ambiguous.
3. List all reasonable interpretations supported by the requirement.
4. Explain the potential impact on later analysis and design activities.
5. Recommend the most reasonable interpretation while clearly noting that clarification may still be required.

Rules:

* Only analyze ambiguities that originate from the requirement document.
* Do not invent additional functionality.
* Do not silently resolve ambiguities.
* Distinguish ambiguity from missing information.
* If multiple interpretations are equally valid, document all of them.

Example:

Requirement:

> A booking request may require approval from a facility staff member or manager.

Ambiguity:

Reason:
The requirement does not specify whether approval is mandatory for all bookings or only certain booking types.

Possible Interpretations:

1. Every booking requires approval.
2. Only selected booking types require approval.

Impact:

* May change workflow design.
* May affect lifecycle analysis.
* May affect later business rule derivation.

Recommended Interpretation:

Approval requirements depend on booking policies and should be clarified with stakeholders.

### Step 8: Analyze Requirement Gaps

Identify information that is missing, incomplete, or insufficiently specified.

#### Assumptions

Document assumptions required to continue analysis.

For each assumption:

* Assumption
* Supporting evidence
* Reason for the assumption
* Risk if the assumption is incorrect

Rules:

* Minimize assumptions whenever possible.
* Assumptions must be traceable to a gap in the requirement.
* Clearly distinguish assumptions from facts explicitly stated in the requirement.

Example:

Assumption:
A user may submit multiple booking requests.

Supporting Evidence:
No restriction is specified.

Reason:
Multiple requests are common in space reservation scenarios.

Risk:
Cardinality and usage policies may change if the assumption is incorrect.

---

#### Open Questions

Document unresolved questions that should be clarified with stakeholders.

For each question:

* Question
* Related requirement section
* Why clarification is needed
* Impact on subsequent analysis if unanswered

Rules:

* Questions must originate from missing, unclear, or conflicting requirements.
* Do not create speculative questions unrelated to the business requirements.
* Prioritize questions that may affect business rules, workflows, approval processes, lifecycle behavior, or system scope.

Example:

Question:
Can an approved booking be modified after approval?

Related Requirement:
Booking Management

Why Clarification Is Needed:
The booking lifecycle does not describe post-approval modifications.

Impact:
May affect workflow analysis, status transitions, and later business rule derivation.

## Important rules

### Scope Restrictions Rules

This stage is not responsible for:

* Entity identification
* Attribute identification
* Relationship identification
* Cardinality analysis
* Business rule extraction

Those activities belong to later stages.

### Example Usage Rules

Examples used in this skill are illustrative only.

Do not reuse example entities, actors, activities, or business rules from the examples.

Always derive results exclusively from the provided business requirements.

---

## Output Specification

Create or update:

`docs/business-analysis/understand-req.md`

The document must follow the template:

`.opencode/skills/business-analysis/understand-req/understand-req-template.md`

Do not omit any required section.

---

## Validation Checklist

Before saving the artifact, verify:

* Problem statement is documented.
* Business purpose is documented.
* Expected outcomes are documented.
* At least one actor is identified.
* Every actor has responsibilities.
* Major business activities are identified.
* Scope boundaries are documented.
* Ambiguities are documented.
* Assumptions are documented.
* Open questions are documented.
* No entities are proposed.
* No relationships are proposed.
* No business rules are extracted.

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