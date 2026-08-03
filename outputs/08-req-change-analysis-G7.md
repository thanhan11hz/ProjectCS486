# Requirement Change Analysis

Baseline: `outputs/01-business-req-analysis-G7.md` (Phase 1)
Changed requirements: `req/business-requirement-change.md` (Phase 2)

---

## 1. Requirement Change Summary

| ID    | Requirement Change | Classification | Source |
| ----- | ------------------ | -------------- | ------ |
| RC-01 | Maintenance records are assigned an impact level: out-of-service (space unusable) or advisory (space usable, but requester must be notified of the advisory). | New | `req/business-requirement-change.md` — "Requirement change: maintenance impact levels" |
| RC-02 | Advisory maintenance no longer prevents booking; the system must notify the requester of all active advisories at booking time and record the requester's acknowledgement with the booking. | New | `req/business-requirement-change.md` — "Requirement change: maintenance impact levels", Additional rules |
| RC-03 | A space may now have several active maintenance records at the same time, with different impact levels. | Modified | `req/business-requirement-change.md` — "Additional rules" (supersedes Phase 1 rule that overlapping active maintenance records should not exist, BR-19) |
| RC-04 | The impact level of an open maintenance record may be escalated (advisory → out-of-service) or downgraded. | New | `req/business-requirement-change.md` — "Additional rules" |
| RC-05 | When advisory maintenance is escalated to out-of-service, the system must support identifying already-approved bookings that overlap the maintenance period, so staff can contact the requesters. | New | `req/business-requirement-change.md` — "Additional rules" |
| RC-06 | For selected space types, booking requests that satisfy the usage policy may be approved automatically at submission time (instant booking). | New | `req/business-requirement-change.md` — "New operating conditions: concurrent booking and approval" |
| RC-07 | The rule that two approved bookings cannot use the same space during overlapping time periods must remain valid under simultaneous booking and approval operations, for both instant and staff-approved bookings. | Modified | `req/business-requirement-change.md` — "New operating conditions: concurrent booking and approval" (strengthens BR-14) |
| RC-08 | New reporting needs: approved booking hours per space per semester; approved bookings by weekday and hour; available spaces matching capacity and facility list in a time period; approved bookings affected by escalation to out-of-service. | New | `req/business-requirement-change.md` — "New reporting needs" |

---

## 2. Affected Business Processes

| Business Process | Requirement Changes | Description |
| ---------------- | ------------------- | ----------- |
| Space booking | RC-01, RC-02, RC-03 | Booking a space with active advisory maintenance remains possible; the requester must be informed of all active advisories and the acknowledgement must be recorded with the booking. Booking remains impossible for periods overlapping out-of-service maintenance. |
| Booking approval | RC-06, RC-07 | The single staff-approval workflow is extended with an instant booking path for selected space types that satisfy the usage policy; the remaining requests continue through staff approval. Both paths must respect the same no-conflict rule under concurrent operations. |
| Maintenance management | RC-01, RC-03, RC-04, RC-05 | Maintenance records gain an impact level; multiple active records per space are allowed; impact levels can be escalated or downgraded while the record is open; escalation to out-of-service triggers identification of affected approved bookings. |
| Conflict detection | RC-07 | The no-overlapping-approved-bookings rule must hold even when availability is checked and results are recorded simultaneously by multiple users and staff. |
| Reporting and utilization analysis | RC-08 | New operational reports are required over accumulated booking and maintenance history. |

---

## 3. Affected Business Entities

Do not propose new entities unless explicitly required by the updated requirements.

| Entity | Requirement Changes | Description |
| ------ | ------------------- | ----------- |
| Maintenance Record | RC-01, RC-03, RC-04, RC-05 | Gains an impact level (out-of-service or advisory); a space may now have several active maintenance records simultaneously with different impact levels; the impact level may change while the record is open; escalation changes the space's booking availability. |
| Booking | RC-02, RC-06, RC-07 | A booking may now be created against a space with active advisory maintenance and must carry the requester's acknowledgement of being informed of the advisories; some bookings may be approved automatically at submission; the no-conflict rule applies to all bookings under concurrent operations. |
| Space | RC-01, RC-02, RC-03, RC-05 | Booking availability of a space is now determined by the impact level of its active maintenance records rather than by the mere existence of active maintenance; a space may host multiple active maintenance records at once. |

Note: no new business entity is explicitly required by the updated requirements. All changes operate on existing business entities (Maintenance Record, Booking, Space).

---

## 4. Affected Business Attributes

Identify only the attributes explicitly introduced or modified by the updated requirements.

Do not infer implementation-specific attributes.

| Entity | Attribute | Requirement Changes | Description |
| ------ | --------- | ------------------- | ----------- |
| Maintenance Record | Impact level | RC-01, RC-04 | The severity of the maintenance with respect to space usability: out-of-service (space unusable; booking blocked for overlapping periods) or advisory (space usable; notification required). The level may be escalated or downgraded while the record is open. |
| Booking | Advisory acknowledgement | RC-02 | Records that the requester was informed of all active advisories on the space at booking time. |

Note: no other attributes are explicitly introduced or modified by the updated requirements. Business concepts such as "notification of advisories" and "affected approved bookings" are recorded as business concepts here; their concrete representation belongs to later design stages.

---

## 5. Affected Business Relationships

| Relationship | Change Type | Requirement Changes | Description |
| ------------ | ----------- | ------------------- | ----------- |
| pertains_to (Maintenance Record → Space) | Modified | RC-01, RC-03 | Semantics change: a space may now have several active maintenance records simultaneously with different impact levels, instead of avoiding overlapping active records. Each record still describes a single space. |
| reserves (Booking → Space) | Modified | RC-02, RC-07 | Semantics change: a booking for a space with active advisory maintenance is permitted when the requester is notified and acknowledges; the booking's validity under overlapping-time constraints applies equally to instant and staff-approved bookings created concurrently. |

No relationships are added or removed by the updated requirements.

---

## 6. Business Rule Changes

| Rule ID | Business Rule | Classification | Related Requirement |
| ------- | ------------- | -------------- | ------------------- |
| BR-14 | The same space cannot have two approved bookings with overlapping time periods. | Modified | RC-07 — the rule now explicitly covers both instant and staff-approved bookings and must hold under simultaneous operations. |
| BR-19 | A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records. | Removed | RC-03 — superseded by the new rule that a space may have several active maintenance records at the same time with different impact levels. |
| BR-32 | A space with status under_maintenance, temporarily_closed, or retired cannot be booked. | Modified | RC-01, RC-02 — refined for maintenance: only active out-of-service maintenance blocks booking; a space with only advisory maintenance may be booked. |
| BR-33 | A maintenance record with status reported or in_progress prevents the related space from being booked. | Modified | RC-01, RC-02 — booking is prevented only by active maintenance records with impact level out-of-service, for overlapping periods. |
| BR-42 | Each maintenance record has an impact level: out-of-service or advisory. | New | RC-01 |
| BR-43 | A space may have several active maintenance records at the same time, with different impact levels. | New | RC-03 |
| BR-44 | A space with an active out-of-service maintenance record cannot be booked for any time period overlapping the maintenance period. | New | RC-01 (replaces the Phase 1 blanket maintenance-blocking behavior) |
| BR-45 | A space with only active advisory maintenance records may be booked; the requester must be notified of all active advisories at booking time. | New | RC-02 |
| BR-46 | The booking must record the requester's acknowledgement that they were informed of the active advisories. | New | RC-02 |
| BR-47 | The impact level of an open maintenance record may be escalated (advisory → out-of-service) or downgraded. | New | RC-04 |
| BR-48 | When advisory maintenance is escalated to out-of-service, all approved bookings overlapping the maintenance period must be identifiable so staff can contact the requesters. | New | RC-05 |
| BR-49 | For selected space types, booking requests satisfying the usage policy are approved automatically at submission time. | New | RC-06 |
| BR-50 | The no-overlapping-approved-bookings rule (BR-14) must hold regardless of whether bookings are created through instant booking or staff approval, and even when multiple users and staff operate concurrently. | New | RC-07 |

---

## 7. Concurrency Conflict Analysis

Identify all possible business-level conflicts introduced by concurrent operations.

Do not propose implementation mechanisms.

| Conflict ID | Concurrent Operations | Shared Business Resource | Business Rule at Risk | Required Business Invariant |
| ----------- | --------------------- | ------------------------ | --------------------- | --------------------------- |
| CC-01 | Two users submit instant bookings for the same space and overlapping time period at approximately the same time. | The space's availability for the requested time period | BR-14, BR-50 | At any time, at most one approved booking exists for a given space and time period; two approved bookings must never overlap for the same space. |
| CC-02 | A staff member approves a pending booking while another user submits (or another staff member approves) a booking for the same space and overlapping period. | The space's availability for the requested time period | BR-14, BR-49, BR-50 | Approval decisions and instant approvals for the same space must never result in overlapping approved bookings. |
| CC-03 | A user submits or a staff member approves a booking for a space while a maintenance record for that space is escalated to out-of-service covering the requested period. | The space's booking availability and its active maintenance state | BR-44, BR-48 | A space covered by active out-of-service maintenance for a period must not have approved bookings overlapping that period; escalation must surface every already-approved booking affected by the new out-of-service period. |
| CC-04 | A booking is submitted/approved for a space at the same time a new advisory maintenance record (or an additional active advisory) is recorded for that space. | The space's set of active advisories | BR-45, BR-46 | Every booking made while advisories are active must have its requester notified of all active advisories and the acknowledgement recorded; a booking must not silently miss an advisory that became active at booking time. |
| CC-05 | Two staff members record maintenance escalation/downgrade decisions for the same space at the same time, or a downgrade occurs concurrently with booking submissions. | The maintenance state of the space | BR-47, BR-44, BR-48 | The impact level of an open maintenance record must have a single consistent current value at any point in time; bookings and affected-booking identifications must reflect the current impact level consistently. |

---

## 8. Assumptions

| ID   | Assumption | Justification |
| ---- | ---------- | ------------- |
| A-01 | The two impact levels defined in the requirements (out-of-service and advisory) are exhaustive for now; other levels are not introduced. | The requirements define exactly these two levels and only these two appear in the escalation example. |
| A-02 | "Selected space types" for instant booking are determined by the usage policy; the exact set of space types and policy conditions is not specified in the requirements. | RC-06 states instant booking applies "for selected space types" and to requests "that satisfy the usage policy" without enumerating them. |
| A-03 | The advisory acknowledgement is recorded as part of the booking's own business information; the exact form (e.g., when it is captured, who confirms it) is left to later stages. | RC-02 states the acknowledgement is "stored with the booking" without further detail. |
| A-04 | The escalation/downgrade of impact level applies while the maintenance record is open (not completed). | The requirements say "while the maintenance is still open". |
| A-05 | Reporting (RC-08) is a consumer of booking and maintenance history only; it introduces no new captured business information beyond the existing history. | The reports are all derived from already-defined booking, space, facility, and maintenance concepts. |
| A-06 | "Notify the requester of all active advisories at booking time" is a business-level obligation; the mechanism of notification is outside this stage's scope. | RC-02 describes the business obligation, not the notification mechanism. |

---

## 9. Open Questions

| ID   | Question | Reason |
| ---- | -------- | ------ |
| Q-01 | Which space types are eligible for instant booking, and what exactly does "satisfy the usage policy" require? | Required to scope RC-06 behavior precisely; the requirements do not enumerate them. |
| Q-02 | When a booking is created while advisories are active, how is the requester's acknowledgement confirmed (explicit consent at submission, or confirmation by the requester)? | RC-02 requires the acknowledgement be recorded but does not define how it is obtained. |
| Q-03 | Can the impact level be downgraded below advisory (e.g., to a "no impact" state), or is advisory the minimum? | The requirements only give the advisory → out-of-service escalation example and mention downgrade generally. |
| Q-04 | When maintenance is escalated to out-of-service and affected approved bookings are found, may those bookings be cancelled, or must staff only contact the requesters? | RC-05 requires identifying affected bookings so staff can contact requesters, but does not state what staff may then do (e.g., cancel, reschedule, keep with requester consent). |
| Q-05 | How soon after an advisory is active must a booking-time notification capture it (i.e., what counts as "at booking time")? | Relevant for CC-04; the boundary between "notified" and "not notified" is not defined. |
| Q-06 | Is there a maximum number of simultaneous active maintenance records per space, or is it unlimited? | RC-03 removes the previous overlap restriction without specifying an upper bound. |

---

## 10. Traceability Matrix

| Requirement Change | Business Process | Entity | Relationship | Business Rule |
| ------------------ | ---------------- | ------ | ------------ | ------------- |
| RC-01 | Maintenance management; Space booking | Maintenance Record; Space | pertains_to (Modified) | BR-32, BR-33, BR-42, BR-44 |
| RC-02 | Space booking | Booking; Space | reserves (Modified) | BR-32, BR-33, BR-45, BR-46 |
| RC-03 | Maintenance management | Maintenance Record; Space | pertains_to (Modified) | BR-19 (Removed), BR-43 |
| RC-04 | Maintenance management | Maintenance Record | pertains_to (Modified) | BR-47 |
| RC-05 | Maintenance management | Maintenance Record; Booking | — | BR-48 |
| RC-06 | Booking approval | Booking | reserves (Modified) | BR-49 |
| RC-07 | Booking approval; Conflict detection | Booking; Space | reserves (Modified) | BR-14, BR-50 |
| RC-08 | Reporting and utilization analysis | Booking; Space; Maintenance Record | — | — |

---

## 11. Analysis Summary

**Major requirement changes:**

- Maintenance becomes impact-aware: out-of-service maintenance blocks overlapping bookings; advisory maintenance allows booking with requester notification and recorded acknowledgement.
- A space may now hold several simultaneously active maintenance records with different impact levels.
- Impact levels of open maintenance records may be escalated or downgraded; escalation to out-of-service requires identifying affected approved bookings.
- A new instant booking path auto-approves qualifying requests for selected space types at submission.
- The no-conflict booking rule is extended to hold under concurrent operations across both booking paths.
- Four new reporting needs over booking and maintenance history.

**Major business impacts:**

- Booking availability semantics change from "any active maintenance blocks" to "out-of-service blocks, advisory notifies".
- The booking process gains a notification/acknowledgement obligation tied to active advisories.
- The approval workflow is split into instant and staff-review paths.
- The maintenance lifecycle gains level changes, and escalations interact with existing bookings.

**Major concurrency concerns:**

- Simultaneous bookings/approvals for the same space can produce overlapping approved bookings (CC-01, CC-02).
- Concurrent escalation to out-of-service versus booking submission/approval can produce bookings on an unusable space (CC-03) or miss affected approved bookings.
- Concurrent advisory creation versus booking submission can bypass the notification obligation (CC-04).
- Concurrent escalation/downgrade actions must leave a single consistent impact level (CC-05).

**Outstanding assumptions:** A-01 to A-06 (impact level exhaustiveness, instant-booking scope, acknowledgement form, open-record level changes, reporting being derived, notification mechanism).

**Outstanding questions:** Q-01 to Q-06 (instant-booking eligibility, acknowledgement confirmation, downgrade bounds, post-escalation booking handling, "at booking time" boundary, active-record limits).

This document identifies business changes only. No ERD, relational schema, migration, or SQL implementation decisions are included.
