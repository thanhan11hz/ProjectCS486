# Step 15: Index Tuning Benchmark Results & Index Inventory

**File:** `outputs/15-index-tuning-results-G7.md`  
**Group:** G7  
**Benchmark Target:** 100,000+ Record Database Workload Performance Analysis  

---

## 1. Workload Execution Time Summary

The following empirical baseline and post-tuning execution time metrics were recorded using T-SQL timing harnesses (`SYSDATETIME()` / `DATEDIFF` and `SET STATISTICS TIME ON`) with cold cache initialization (`CHECKPOINT; DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;`).

| Workload ID | Query Description | Baseline Time (ms) | Post-Tuning Time (ms) | Absolute Gain (ms) | Performance Gain (%) | Speedup Factor |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **W1** | **Booking Conflict Check** | 6 | 0 | -6 ms | **100.0%** | **Instant (Sub-ms)** |
| **W2** | **Multi-Criteria Room Finder** | 197 | 64 | -133 ms | **67.5%** | **3.08x Faster** |
| **W3** | **Total Approved Hours per Space** | 31 | 15 | -16 ms | **51.6%** | **2.07x Faster** |
| **W4** | **Booking Density Heatmap** | 23 | 7 | -16 ms | **69.6%** | **3.29x Faster** |
| **W5** | **Maintenance Escalation Impact** | 19 | 3 | -16 ms | **84.2%** | **6.33x Faster** |

---

## 2. Execution Plan Access Paths & Row Scan Reduction

The table below illustrates the shift in physical execution plan operators and data access volume before and after index implementation. Prior to tuning, queries were forced to execute full **Clustered Index Scans**, evaluating up to millions of records. Post-tuning, SQL Server transitioned to targeted **NonClustered Index Seeks**, drastically reducing total row scans and physical disk page reads.

| Workload ID | Target Table | Baseline Access Path | Baseline Rows Read | Post-Tuning Access Path | Post-Tuning Rows Read | Row Read Reduction |
| :--- | :--- | :--- | :---: | :--- | :---: | :---: |
| **W1** | `bookings` | Clustered Index Scan | 125,971 | NonClustered Index Seek | 348 | **99.72%** |
| **W2** | `bookings` | Clustered Index Scan | 2,015,536 | NonClustered Index Seek | 33,312 | **98.35%** |
| **W2** | `maintenance_records` | Clustered Index Scan | 47,182 | NonClustered Index Seek | 16 | **99.97%** |
| **W3** | `bookings` | Clustered Index Scan | 125,971 | NonClustered Index Seek | 12,599 | **90.00%** |
| **W4** | `bookings` | Clustered Index Scan | 125,971 | NonClustered Index Seek | 12,599 | **90.00%** |
| **W5** | `bookings` | Clustered Index Scan | 125,971 | NonClustered Index Seek | 247 | **99.80%** |

---

## 3. Comprehensive Database Index Inventory

The database engine contains **10 total indexes** (5 baseline system constraints + 5 custom non-clustered performance indexes deployed during tuning).

### 3.1 Baseline System Indexes (5 Total)

| Table Name | Index Name | Index Type | Filter Predicate | Is PK | Is Unique | Description / Baseline Purpose |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| `bookings` | `pk_bookings` | `CLUSTERED` | `NULL` | 1 | 1 | Primary Key constraint on `booking_id`. |
| `maintenance_records` | `pk_maintenance_records` | `CLUSTERED` | `NULL` | 1 | 1 | Primary Key constraint on `maintenance_id`. |
| `space_facilities` | `pk_space_facilities` | `CLUSTERED` | `NULL` | 1 | 1 | Composite Primary Key on `(space_code, facility_id)`. |
| `spaces` | `pk_spaces` | `CLUSTERED` | `NULL` | 1 | 1 | Primary Key constraint on `space_code`. |
| `spaces` | `uq_spaces_building_floor_room` | `NONCLUSTERED` | `NULL` | 0 | 1 | Unique constraint enforcing location integrity. |

---

### 3.2 Custom Non-Clustered & Filtered Performance Indexes (5 Total)

Five specialized non-clustered indexes (`I-1` through `I-5`) were created in `outputs/15-index-tuning-G7.sql` to optimize execution plans across all target workloads.

| ID | Target Table | Index Name | Type | Key Columns | Included Payload Columns (`INCLUDE`) | Filter Predicate (`WHERE`) | Serves Workload |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **I-1** | `bookings` | `ix_bookings_conflict_approved` | `NONCLUSTERED` | `(space_code, requested_start_time, requested_end_time)` | — | `([status]='approved')` | **W1** conflict probe |
| **I-2** | `bookings` | `ix_bookings_space_effective_covering` | `NONCLUSTERED` | `(space_code, requested_start_time)` | `requested_end_time` | `([status] IN ('approved', 'checked_in', 'completed', 'no_show'))` | **W3** (Q1) per-space aggregation; **W2** (Q3) bookings anti-join |
| **I-3** | `bookings` | `ix_bookings_status_semester_covering` | `NONCLUSTERED` | `(requested_start_time)` | — | `([status] IN ('approved', 'checked_in', 'completed', 'no_show'))` | **W4** (Q2) heatmap aggregation |
| **I-4** | `maintenance_records` | `ix_maintenance_open_covering` | `NONCLUSTERED` | `(space_code, impact_level, start_time, completion_time)` | — | `([status] IN ('reported', 'in_progress'))` | BR-44/BR-45 probes; **W2** (Q3) maintenance anti-join |
| **I-5** | `bookings` | `ix_bookings_escalation_impact` | `NONCLUSTERED` | `(space_code)` | `requested_start_time, requested_end_time, requester_id` | `([status]='approved')` | **W5** (Q4) escalation impact report |

---

## 4. Technical Guardrails & Implementation Discoveries

### 1. Data Type Matching in Filtered Indexes (`Msg 10611` Prevention)
A critical discovery during this benchmark stage is that SQL Server prohibits implicit data type or collation conversions within filtered index `WHERE` clauses. 
* **Finding:** Because the `status` and `impact_level` columns in this database schema are defined as `VARCHAR(20)` (rather than `NVARCHAR`), passing Unicode literals (e.g., `WHERE status = N'approved'`) causes compilation error `Msg 10611`.
* **Resolution:** All filtered index predicates explicitly utilize plain `VARCHAR` literals (e.g., `WHERE status = 'approved'`), aligning literal types with column definitions and allowing successful index compilation and seek matching.

### 2. Strategic Use of the `INCLUDE` Clause
* Columns required for range navigation, equality filtering (`WHERE`), and joining (`ON`) are placed in the **Index Key**.
* Columns needed strictly for scalar calculations, output expressions, or aggregation payloads (`SELECT`) are placed in the **`INCLUDE`** clause.
* **Benefit:** Storing non-key payload columns only at the B-tree leaf nodes prevents Key Lookups against the main clustered table while maintaining a lean, fast-navigating B-tree key structure.

---

## 5. Detailed Query Tuning Analysis

### W1 — Booking Conflict Check
* **Baseline:** Executed a full Clustered Index Scan across 125,971 booking records (6 ms) using `pk_bookings`.
* **Optimization:** Applied index **`I-1`** (`ix_bookings_conflict_approved`). Because conflict probes only check active approved reservations, the index filter `status = 'approved'` excludes cancelled, draft, or rejected rows.
* **Result:** Reduced rows evaluated from 125,971 down to 348 (**99.72% reduction**), bringing execution time down to **0 ms (sub-millisecond)**.

### W2 — Multi-Criteria Room Finder (Q3)
* **Baseline:** Scanned 2,015,536 booking rows via `pk_bookings` and 47,182 maintenance rows via `pk_maintenance_records` using nested loop scans (197 ms).
* **Optimization:** Leveraged **`I-2`** for booking anti-joins, **`I-4`** for maintenance verification, and primary key indexes on spatial dimension tables:
  * **`I-4`** executes efficient anti-joins to verify zero active out-of-service maintenance.
  * **`I-2`** eliminates overlapping booking searches.
* **Result:** Maintenance row reads dropped from 47,182 to just 16 (**99.97% reduction**). Booking checks dropped by **98.35%**. Total execution time dropped from 197 ms to 64 ms (**3.08x speedup**).

### W3 — Total Approved Booking Hours per Space (Q1)
* **Baseline:** Full Clustered Index Scan (`pk_bookings`) evaluating all historical booking records across 125,971 rows (31 ms).
* **Optimization:** Leveraged index **`I-2`** (`ix_bookings_space_effective_covering`). Placing `space_code` and `requested_start_time` in the key enables SQL Server to seek directly to the semester date window. Placing `requested_end_time` in `INCLUDE` supplies the payload for `DATEDIFF` calculations with zero Key Lookups.
* **Result:** Row reads decreased by **90.00%** (12,599 rows read), cutting execution time to 15 ms (**51.6% performance gain**).

### W4 — Booking Density Heatmap (Q2)
* **Baseline:** Full Clustered Index Scan (`pk_bookings`) reading 125,971 rows to group by weekday and hour (23 ms).
* **Optimization:** Leveraged index **`I-3`** (`ix_bookings_status_semester_covering`). The key `(requested_start_time)` allows a continuous range seek through time for the effective booking statuses across the entire campus (the filter `status IN (...)`, not a key column, restricts the index to those statuses).
* **Result:** Evaluated rows dropped by **90.00%** (12,599 rows read), reducing execution time to 7 ms (**3.29x speedup**).

### W5 — Maintenance Escalation Impact (Q4)
* **Baseline:** Full Clustered Index Scan (`pk_bookings`) evaluating 125,971 rows to find approved bookings affected by an escalated maintenance window (19 ms).
* **Optimization:** Applied index **`I-5`** (`ix_bookings_escalation_impact`). The key `(space_code)` seeks directly to the target room's approved bookings (the filter `status = 'approved'`, not a key column, restricts the index to approved rows), while `INCLUDE (requested_start_time, requested_end_time, requester_id)` supplies requester contact details without returning to the base table.
* **Result:** Rows read dropped from 125,971 to 247 (**99.80% reduction**), bringing execution time down to 3 ms (**84.2% gain, 6.33x speedup**).