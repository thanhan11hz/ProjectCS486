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