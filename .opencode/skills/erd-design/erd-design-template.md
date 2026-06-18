# Conceptual ERD Design

## 1. Entity Definitions

| Entity | Description |
| ------ | ----------- |
|        |             |

---

## 2. Attributes 

### Entity: [Entity Name]

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
|           |             |       |

Repeat for every entity.

---

## 4. Relationships

| Relationship | Degree | Relationship Attributes | Participating Entities | Description |
| ------------ | ------ | ----------------------- | ---------------------- | ----------- |
|              |        |                         |                        |             |


---

## 4. Cardinality and Participation Summary

| Relationship | Cardinality | Participation | 
| ------------ | ----------- | ------------- |
|              |             |               |        

---

## 5. Conceptual ERD Diagram

```mermaid
flowchart LR

%% =========================
%% Entities
%% =========================

%% Example:
%% User[User]

%% =========================
%% Attributes
%% =========================

%% Example:
%% UserID((user_id))
%% FullName((full_name))

%% =========================
%% Relationships
%% =========================

%% Example:
%% Submits{Submits}

%% =========================
%% Entity-Attribute Links
%% =========================

%% Example:
%% User --- UserID
%% User --- FullName

%% =========================
%% Relationship Links
%% =========================

%% Example:
%% User -- "1..N" --- Submits
%% Submits -- "1" --- Booking

```

---

## 6. ERD Validation

### Entity Coverage

* [ ] Every accepted entity appears in the ERD.
* [ ] No rejected candidate appears as an entity.

### Attribute Coverage

* [ ] Every major attribute appears in the ERD.

### Relationship Coverage

* [ ] Every relationship appears in the ERD.
* [ ] Every relationship includes cardinality information.

### Participation Coverage

* [ ] Participation constraints are documented where known.

### Conceptual Modeling Compliance

* [ ] No primary keys shown.
* [ ] No foreign keys shown.
* [ ] No junction tables shown.
* [ ] No SQL concepts shown.
* [ ] Chen notation semantics preserved.

### Diagram Validation

* [ ] Mermaid syntax is valid.
* [ ] Mermaid Flowchart notation is used.
* [ ] Mermaid ERD notation is not used.

---

