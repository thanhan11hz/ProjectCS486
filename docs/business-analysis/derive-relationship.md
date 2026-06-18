# Relationship Analysis

## 1. Candidate Relationships

| Relationship Candidate | Evidence | Notes |
| ---------------------- | -------- | ----- |
| User submits Booking | Line 19: "Users can submit booking requests" | Requester creates a booking. |
| Booking reserves Space | Line 19: "selecting a space" | Each booking is for one space. |
| User makes Approval | Line 23: "records the staff member who made the decision" | Staff/manager approves or rejects. |
| Approval reviews Booking | Line 23: "When a booking is approved or rejected" | Decision is on a specific booking. |
| User conducts Session | Line 25: "the person who checked in the booking" | Staff performs check-in/completion. |
| Session tracks Booking | Line 25: "check in the booking" / "complete the booking" | Session is the actual usage of a booking. |
| User reports Maintenance Record | Line 27: "reporter" | User reports a maintenance issue. |
| Maintenance Record pertains_to Space | Line 27: "related space" | Maintenance is for a specific space. |
| Space equipped_with Facility | Line 17: "the list of facilities available in each space" | Many-to-many; a space can have multiple facilities and a facility can be in multiple spaces. |
| User assigned_to Maintenance Record | Line 27: "assigned staff member" | Staff assigned to resolve maintenance. |

---

## 2. Relationship Evaluation

### Approved Relationships

| Relationship | Reason |
| ------------ | ------ |
| User submits Booking | Genuine business association. Supported by requirements. Verb-based name. |
| Booking reserves Space | Genuine business association. Supported by requirements. Verb-based name. |
| User makes Approval | Genuine business association. Different business role from "submits". |
| Approval reviews Booking | Genuine business association. Supported by requirements. |
| User conducts Session | Genuine business association. Different business role. |
| Session tracks Booking | Genuine business association. Supported by requirements. |
| User reports Maintenance Record | Genuine business association. Supported by requirements. |
| Maintenance Record pertains_to Space | Genuine business association. Supported by requirements. |
| Space equipped_with Facility | Genuine business association. M:N relationship explicitly described. |
| User assigned_to Maintenance Record | Genuine business association. Distinct business role from "reports" (Rule 4). |

### Rejected Relationships

| Relationship Candidate | Rejection Reason | Violated Rule |
| ---------------------- | ---------------- | ------------- |
| User manages Space | Derived through User → Booking → Space. No direct association in requirements. | Rule 3 — Derived Relationship |
| User views Session | Derived through User → Booking → Session. No direct business action. | Rule 3 — Derived Relationship |
| User resolves Maintenance Record | Overlaps with "assigned_to"; same business role. | Duplicate relationship |
| Facility belongs_to Space | "equipped_with" is more business-meaningful per Rule 2. | Rule 2 — Generic Name |

---

## 3. Approved Relationship Details

### Relationship: submits

#### Business Meaning

A user (requester) creates a booking request to reserve a space.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| User | Requester |
| Booking | Booking Request |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| User | 1 |
| Booking | N |

One user can submit many bookings. Each booking is submitted by exactly one user.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| User | Optional |
| Booking | Mandatory |

A user may exist without submitting any bookings. Every booking must have a submitting user.

#### Relationship Attributes

> No relationship attributes identified.

The submission timestamp is an attribute of Booking (creation timestamp), not of the relationship.

#### Evidence

Line 19: "Users can submit booking requests by selecting a space, requested start time, requested end time, purpose of use, and expected number of participants."

---

### Relationship: reserves

#### Business Meaning

A booking request reserves a specific space for a defined time period.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| Booking | Booking Request |
| Space | Reserved Space |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| Booking | 1 |
| Space | N |

Many bookings can reserve the same space (at different times). Each booking reserves exactly one space (Assumption A-01).

#### Participation

| Entity | Participation |
| ------ | ------------- |
| Booking | Mandatory |
| Space | Optional |

Every booking must reserve a space. A space may exist without any current bookings.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 19: "selecting a space."
Assumption A-01: "A booking request is always associated with a single space."

---

### Relationship: makes

#### Business Meaning

A facility staff member or manager makes an approval decision (approve or reject) on a booking request.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| User | Decision Maker |
| Approval | Approval Decision |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| User | 1 |
| Approval | N |

One staff member can make many approval decisions. Each approval is made by exactly one staff member.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| User | Optional |
| Approval | Mandatory |

Not all users are decision makers. Every approval must have a decision maker.

#### Relationship Attributes

> No relationship attributes identified.

Decision time, decision note, and rejection reason are attributes of Approval, not of the relationship.

#### Evidence

Line 23: "When a booking is approved or rejected, the system records the staff member who made the decision."

---

### Relationship: reviews

#### Business Meaning

An approval decision reviews and determines the outcome of a specific booking request.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| Approval | Approval Decision |
| Booking | Reviewed Booking |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| Approval | 1 |
| Booking | 1 |

One approval reviews exactly one booking. One booking receives at most one approval decision (Assumption A-02).

#### Participation

| Entity | Participation |
| ------ | ------------- |
| Approval | Mandatory |
| Booking | Optional |

Every approval must review a booking. Not all bookings receive an approval decision (some may be cancelled before review).

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 23: "A booking request may require approval from a facility staff member or manager."
Assumption A-02: "A booking can have at most one approval decision."

---

### Relationship: conducts

#### Business Meaning

Facility staff conduct a usage session by performing check-in and completion operations.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| User | Staff Conductor |
| Session | Usage Session |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| User | 1 |
| Session | N |

One staff member can conduct many sessions. Each session is conducted by exactly one staff member (the person who checked in).

#### Participation

| Entity | Participation |
| ------ | ------------- |
| User | Optional |
| Session | Mandatory |

Not all users are facility staff who conduct sessions. Every session must have a conductor.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 25: "the person who checked in the booking."

---

### Relationship: tracks

#### Business Meaning

A session records the actual usage that corresponds to an approved booking, capturing real versus requested data.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| Session | Actual Usage |
| Booking | Approved Booking |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| Session | 1 |
| Booking | 1 |

One session tracks exactly one booking. One booking has at most one session (Assumption A-03). Some bookings never result in a session (no-show).

#### Participation

| Entity | Participation |
| ------ | ------------- |
| Session | Mandatory |
| Booking | Optional |

Every session must track a booking. Not all bookings result in a session.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 25: "facility staff can check in the booking."
Assumption A-03: "A session is always linked to exactly one approved booking."

---

### Relationship: reports

#### Business Meaning

A user reports a maintenance issue, creating a maintenance record for a space.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| User | Reporter |
| Maintenance Record | Maintenance Record |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| User | 1 |
| Maintenance Record | N |

One user can report many maintenance issues. Each maintenance record is reported by exactly one user.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| User | Optional |
| Maintenance Record | Mandatory |

Not all users report maintenance. Every maintenance record must have a reporter.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 27: "Each maintenance record stores the related space, reporter, assigned staff member, problem description, start time, completion time, status, and result note."

---

### Relationship: pertains_to

#### Business Meaning

A maintenance record describes an issue with a specific space.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| Maintenance Record | Maintenance Record |
| Space | Affected Space |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| Maintenance Record | 1 |
| Space | N |

Many maintenance records can pertain to the same space. Each maintenance record pertains to exactly one space.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| Maintenance Record | Mandatory |
| Space | Optional |

Every maintenance record must pertain to a space. A space may have no maintenance records.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 27: "Each maintenance record stores the related space."

---

### Relationship: equipped_with

#### Business Meaning

A space is equipped with various facilities. A facility may be available in multiple spaces.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| Space | Space |
| Facility | Facility |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| Space | M |
| Facility | N |

A space may have many facilities. A facility may be equipped in many spaces.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| Space | Optional |
| Facility | Optional |

A space may have no facilities. A facility may not be assigned to any space.

#### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| quantity | Number of units of a facility in a space (Design Consideration DC-01). |

The quantity attribute is not explicitly specified in the requirements (line 17: "list of facilities") but is strongly implied for an M:N allocation relationship per Rule 7.

#### Evidence

Line 17: "Each space may have several facilities, such as a projector, whiteboard, microphone, computer, livestreaming equipment, or air conditioner. The system should store the list of facilities available in each space."

---

### Relationship: assigned_to

#### Business Meaning

A facility staff member is assigned to handle a specific maintenance record.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
| User | Assigned Staff |
| Maintenance Record | Maintenance Record |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
| User | 1 |
| Maintenance Record | N |

One staff member can be assigned to many maintenance records. Each maintenance record has exactly one assigned staff member.

#### Participation

| Entity | Participation |
| ------ | ------------- |
| User | Optional |
| Maintenance Record | Mandatory |

Not all users are assigned staff. Every maintenance record must have an assigned staff member.

#### Relationship Attributes

> No relationship attributes identified.

#### Evidence

Line 27: "assigned staff member."

---

## 4. Relationship Attribute Analysis

| Relationship | Attribute | Justification |
| ------------ | --------- | ------------- |
| Space equipped_with Facility | quantity (DC-01) | M:N allocation relationship. Strongly implied but not explicitly stated in requirements. Recorded as design consideration. |

> No other relationship attributes identified.

---

## 5. Validation Notes

### Relationship Validation

* All approved relationships connect approved entities.
* No duplicate relationships exist.
* No derived relationships were approved.
* No attributes were incorrectly modeled as relationships.
* Distinct business roles on the same entity pair (User–Maintenance Record: reports vs. assigned_to) are preserved as separate relationships (Rule 4).
* The M:N relationship (Space equipped_with Facility) has been examined for attributes per Rule 6.

### Scope Validation

* No new entities were introduced.
* No primary keys were defined.
* No foreign keys were defined.
* No relational schema decisions were made.

### Design Considerations

| ID | Description |
| -- | ----------- |
| DC-01 | The `equipped_with` relationship may require a `quantity` attribute if the same facility type can appear multiple times in a space. This is not explicitly required but is a common extension for equipment allocation. |
