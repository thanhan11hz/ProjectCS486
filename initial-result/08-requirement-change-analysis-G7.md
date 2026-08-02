# Requirement Change Analysis

## 1. Change Overview

The Facility Manager has submitted a change request (`req/business-requirement-change.md`) that refines and extends the Phase 1 requirements documented in `outputs/01-business-req-analysis-G7.md`. The changes fall into three groups:

1. **Maintenance impact levels** — refine the Phase 1 rule "a space under maintenance cannot be booked" by distinguishing out-of-service and advisory maintenance.
2. **Concurrent booking and approval** — introduce instant (automatic) approval for selected space types and require the system to remain conflict-free under concurrent operations.
3. **New reporting needs** — four reporting queries plus indexing requirements to be validated on a large generated dataset.

This document identifies the affected entities, attributes, relationships, and business rules; analyzes the impact on the existing design; and identifies concurrency conflicts. It is the foundation for stages 09 (updated ERD and logical design), 10 (schema migration), 11 (concurrency design), 12 (concurrency implementation), 13 (concurrency tests), 14 (data generator), 15 (index tuning), and 16 (analytical queries).

---

## 2. Requirement Change List

| ID | Change | Description | Source |
|----|--------|-------------|--------|
| RC-01 | Maintenance impact levels | Each maintenance record gets an impact level: `out_of_service` (space cannot be booked for any overlapping period, as in Phase 1) or `advisory` (space remains bookable). | Change §1 |
| RC-02 | Advisory notification and acknowledgement | When a booking is made for a space with active advisory maintenance, the system must notify the requester of all active advisories and record that the requester was informed; the acknowledgement is stored with the booking. | Change §1 |
| RC-03 | Multiple concurrent active maintenance records | A space may have several active maintenance records at the same time, possibly with different impact levels. | Change §1 |
| RC-04 | Impact level escalation / downgrade | The impact level of an open maintenance record may change (advisory → out_of_service, or the reverse) while the maintenance is still open. | Change §1 |
| RC-05 | Affected approved bookings on escalation | When an advisory maintenance is escalated to out_of_service, already-approved bookings that overlap the maintenance period must be identifiable so staff can contact the requesters. | Change §1 |
| RC-06 | Concurrent booking and approval | At semester start, many requests arrive simultaneously. For selected space types, requests satisfying the usage policy are auto-approved at submission (instant booking); others follow staff approval. Multiple operations may check availability concurrently. | Change §2 |
| RC-07 | Concurrency invariant | Two approved bookings must never overlap for the same space, regardless of whether they were created via instant booking or staff approval, even under concurrent operations. | Change §2 |
| RC-08 | Reporting queries | (a) Total approved booking hours per space per semester; (b) number of approved bookings by weekday and hour per semester; (c) available spaces satisfying required capacity and facility list within a time period; (d) approved bookings affected when a maintenance record is escalated to out_of_service. | Change §3 |
| RC-09 | Indexing and large-scale testing | Students must implement all queries, identify suitable indexes for the booking conflict check, the room finder query, and one additional reporting query, and verify the effect on a sufficiently large generated dataset. | Change §3 |

---

## 3. Affected Entities and Attributes

| Entity | Change Type | Attribute | Description |
|--------|-------------|-----------|-------------|
| Maintenance Record | **Add attribute** | `impact_level` | Enumeration: `out_of_service`, `advisory`. Determines whether the space is blockable during the maintenance period. Required for every maintenance record. (RC-01) |
| Maintenance Record | **Add attribute** | `impact_level_changed_at` | Timestamp of the most recent impact level change; supports traceability of escalation/downgrade and supports the affected-bookings report. (RC-04, RC-05) |
| Maintenance Record | **Modify lifecycle** | `status` | Existing enumeration (`reported`, `in_progress`, `completed`) is retained; impact level is independent of status and may change while the record is open. (RC-04) |
| Booking | **Add attribute** | `advisories_acknowledged_at` | Timestamp recording that the requester was informed of all active advisory maintenance on the space at booking/approval time. NULL when no active advisories existed. (RC-02) |
| Booking | **Add attribute** | `acknowledged_advisories` (logical) | Set of active advisory maintenance records the requester was informed about. Requires a link between Booking and Maintenance Record (see §4) to preserve exactly which advisories were acknowledged. (RC-02) |
| Booking | **Modify lifecycle** | `status` | Instant booking must auto-approve at submission for eligible space types, so the `pending → approved` transition becomes automatic in that path; status set itself is unchanged. (RC-06) |
| Space | **Add attribute** | `instant_booking_enabled` | Boolean indicating whether requests for this space (by type, per the requirement "selected space types") qualify for automatic approval at submission when the usage policy is satisfied. (RC-06) |
| Space | **Unchanged** | — | `status` values (`available`, `in_use`, `under_maintenance`, `temporarily_closed`, `retired`) are retained. Availability semantics now depend on active maintenance impact levels, not just `status`. (RC-01) |

### New Candidate Entity (decision deferred to stage 09)

| Entity | Rationale |
|--------|-----------|
| Maintenance Impact Change (history) | Records every impact level change (from, to, changed_at, changed_by) of an open maintenance record. Required for traceability of escalation/downgrade and to answer "affected approved bookings at the moment of escalation" accurately. Stage 09 will decide between this dedicated history table and storing only the current level plus `impact_level_changed_at`. |

---

## 4. Affected Relationships

| Relationship | Change | Description |
|--------------|--------|-------------|
| Booking ↔ Maintenance Record (`informed_about` / `acknowledges`) | **New M:N relationship** | Each booking that occurs while advisory maintenance is active on the reserved space is linked to every active advisory maintenance record that was notified to and acknowledged by the requester. Preserves which advisories were acknowledged per booking (RC-02). |
| Maintenance Record → Space (`pertains_to`) | **Semantics refined** | Participation constraint changes: a space may now have several overlapping *active* maintenance records (RC-03). The blocking effect on booking depends on the record's `impact_level`, not merely on its existence. (RC-01) |
| Space → Booking (`reserves`) | **Semantics refined** | The conflict rule (BR-14) now also covers instant bookings and must hold under concurrency. (RC-06, RC-07) |
| Approval → Booking (`reviews`) | **Partially bypassed** | Instant booking auto-approves at submission; the staff approval workflow (`reviews`) remains mandatory for non-instant requests. The 1:1 "at most one approval" constraint (BR-09) must accommodate an approval created by the system itself for instant bookings. (RC-06) |

---

## 5. Affected Business Rules

### Superseded / Modified Rules

| Phase 1 Rule | Status | New Rule |
|--------------|--------|----------|
| BR-32: A space with status under_maintenance, temporarily_closed, or retired cannot be booked. | **Modified** | BR-42: A space with status `temporarily_closed` or `retired` cannot be booked. A space with status `under_maintenance` is bookable only if no active out-of-service maintenance overlaps the requested period. |
| BR-33: A maintenance record with status reported or in_progress prevents the related space from being booked. | **Superseded** | BR-43: An active (reported/in_progress) maintenance record with impact level `out_of_service` prevents booking of the space for any time period overlapping the maintenance period. Active `advisory` maintenance does not prevent booking. |
| BR-19: A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records. | **Superseded** | BR-44: A space may have several simultaneously active maintenance records with the same or different impact levels. |
| BR-14: The same space cannot have two approved bookings with overlapping time periods. | **Strengthened** | BR-45: The same space cannot have two approved bookings with overlapping time periods, regardless of whether bookings were created by instant booking or staff approval, and this invariant must hold under concurrent operations. |
| BR-24: A booking must have status pending before it can be reviewed for approval or rejection. | **Extended** | BR-46: A booking must have status `pending` before staff review; for instant-eligible bookings, a `pending` booking satisfying the usage policy is automatically approved at submission time. |

### New Rules

| ID | Rule |
|----|------|
| BR-47 | Every maintenance record must have an impact level: `out_of_service` or `advisory`. |
| BR-48 | When a booking is created for a space with active advisory maintenance records, the system must notify the requester of all active advisories and record the acknowledgement with the booking, linking the booking to each acknowledged advisory. |
| BR-49 | A booking of a space with active out-of-service maintenance overlapping the requested period must be rejected or prevented. |
| BR-50 | The impact level of an open maintenance record may be escalated (`advisory` → `out_of_service`) or downgraded (`out_of_service` → `advisory`); the change and its time must be recorded. |
| BR-51 | When an advisory maintenance record is escalated to `out_of_service`, all approved bookings overlapping the maintenance period must be identifiable (for staff to contact requesters). |
| BR-52 | For selected space types (instant booking enabled), a request satisfying the usage policy is approved automatically at submission; all other requests follow the staff approval workflow. |

---

## 6. Impact on the Existing Database Design

| Artifact | Impact |
|----------|--------|
| ERD (02) | Add `impact_level` (+ optional change-history) attributes to Maintenance Record; add acknowledgement attributes and a new M:N relationship between Booking and Maintenance Record; add `instant_booking_enabled` to Space. |
| Logical design (03) | New columns (`impact_level`, `impact_level_changed_at`, `instant_booking_enabled`, `advisories_acknowledged_at`); new junction table `booking_maintenance_acknowledgement` (booking_id, maintenance_id, acknowledged_at) for the M:N relationship; possible new `maintenance_impact_change` history table; revised constraint set for overlapping-active-maintenance (BR-44) and capacity checks unchanged. |
| DDL (05) | Migration, not recreation: `ALTER TABLE` statements adding the new columns; new junction/history tables; updated check constraints and foreign keys (stage 10). |
| Booking conflict logic | The conflict check must be made concurrency-safe (stage 11/12) and must now also consider out-of-service maintenance overlap at approval time (both staff and instant paths). |
| Maintenance availability logic | Booking-blocking decision changes from "any active maintenance" to "active out-of-service maintenance overlapping the period". |
| Sample data (06) | Must be regenerated/extended to include advisory and out-of-service records, escalations, instant bookings, and acknowledgements (stage 14). |
| Queries (07) | Extended with the four new reporting queries and index tuning (stages 15/16). |

No structural changes affect User, Facility, Session, or Approval identities; their tables remain stable apart from approval records possibly being system-generated for instant bookings.

---

## 7. Concurrency Conflict Analysis

The new operating conditions (RC-06) and the escalation rule (RC-04/RC-05) create the following concurrency hazards:

| ID | Scenario | Conflict Type | Description |
|----|----------|---------------|-------------|
| CC-01 | Two users request overlapping periods for the same space at the same time (both instant-eligible) | Lost update / check-then-act race | Both transactions read "space free", both approve → overlapping approved bookings (violates BR-45). |
| CC-02 | One user submits an instant booking while a staff member approves an overlapping request for the same space | Interleaved read / phantom | The approval check and the instant check both observe no conflicting booking before either commits. |
| CC-03 | Staff escalate an advisory maintenance to out_of_service while a request for the overlapping period is being approved | Lost update / availability race | The approval reads space availability before the escalation commits and approves a booking that should be blocked (violates BR-49). |
| CC-04 | Two maintenance records are opened/impact-level-changed for the same space concurrently | Write-write conflict | Impact level changes may be lost or the affected-bookings report may read a stale level. |
| CC-05 | Advisory acknowledgement recorded concurrently with maintenance impact level changes | Inconsistent read | The set of advisories notified to the requester may not match the active advisories at booking time. |

The critical invariant to protect is BR-45 (no overlapping approved bookings), which must hold under CC-01 and CC-02, plus BR-49 (no booking overlapping out-of-service maintenance) under CC-03. The required mechanisms (transactions, isolation levels, locking hints, row versioning, or application-level serialization) and their justification are designed in stage 11 and implemented in stage 12.

---

## 8. Required Design Changes Summary

| # | Required Change | Downstream Stage |
|---|-----------------|------------------|
| 1 | Update ERD: Maintenance Record attributes, Booking acknowledgement, new M:N relationship, Space instant-booking flag | 09 |
| 2 | Update logical schema with new columns, junction table, and optional history table; revise constraints for BR-43/BR-44/BR-47/BR-48/BR-50 | 09 |
| 3 | Schema migration scripts evolving the Phase 1 database | 10 |
| 4 | Concurrency design: choose mechanisms for booking conflict check, instant approval, staff approval, and escalation handling | 11 |
| 5 | Concurrency implementation using SQL Server mechanisms | 12 |
| 6 | Concurrency test scenarios verifying BR-45/BR-49 under simultaneous transactions | 13 |
| 7 | Large-scale realistic data generator covering advisories, escalations, instant bookings, acknowledgements | 14 |
| 8 | Index analysis for booking conflict check, room finder query, and one reporting query; execution-plan-based recommendations | 15 |
| 9 | Analytical queries: booking hours per space per semester; bookings by weekday/hour; room finder with capacity + facilities; affected bookings on escalation | 16 |

---

## 9. Traceability

| Change | Affected Phase 1 Rules | Affected Phase 1 Artifacts | New Outputs |
|--------|------------------------|----------------------------|-------------|
| RC-01 | BR-32, BR-33 | 02, 03, 05, 06 | 09, 10, 14 |
| RC-02 | BR-09 (extension) | 02, 03, 05, 06 | 09, 10, 14 |
| RC-03 | BR-19 | 02, 03, 05 | 09, 10 |
| RC-04, RC-05 | BR-33, BR-14 | 02, 03, 05 | 09, 10, 11, 12, 13, 16 |
| RC-06, RC-07 | BR-14, BR-24 | 03, 05, 06 | 09, 10, 11, 12, 13, 14 |
| RC-08 | — (new reporting scope) | 07 | 16 |
| RC-09 | — (new performance scope) | 07 | 15 |

---

## 10. Assumptions and Open Questions

### Assumptions

| ID | Assumption |
|----|------------|
| A-08 | `instant_booking_enabled` is a property of Space derived from its type (per "selected space types") and stored as an explicit column for flexibility. |
| A-09 | A booking created via instant booking records an approval record with the system (or the approving staff member) as the decision maker, preserving the audit trail. |
| A-10 | Advisory acknowledgement is captured at booking creation time; the linked maintenance records are those active at that moment. |
| A-11 | The impact level history may be kept either as a dedicated history table or as current-level plus last-change timestamp; the choice is finalized in stage 09. |
| A-12 | The concurrency invariant (BR-45) covers the time interval [requested_start_time, requested_end_time) of approved bookings, consistent with Phase 1 conflict semantics. |

### Open Questions

| ID | Question |
|----|----------|
| OQ-01 | Should a booking already approved when out-of-service maintenance is created (not escalated) also be flagged for staff contact, or only on escalation? |
| OQ-02 | What happens to pending requests overlapping a newly escalated out-of-service period — auto-rejected or left for staff? |
| OQ-03 | Which exact space types qualify for instant booking? |
| OQ-04 | Is the requester allowed to proceed with the booking if they decline to acknowledge advisory maintenance, or is acknowledgement mandatory? |
