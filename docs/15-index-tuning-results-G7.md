# Step 15: Index Tuning Benchmark Results & Index Inventory

**File:** `outputs/15-index-tuning-results-G7.md`  
**Group:** G7  
**Benchmark Target:** 100,000+ Record Database Workload Performance Analysis  

---

## 1. Workload Execution Time Summary

The following empirical baseline and post-tuning execution time metrics were recorded using T-SQL timing harnesses (`SYSDATETIME()` / `DATEDIFF` and `SET STATISTICS TIME ON`) with cold cache initialization (`CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;`).

| Workload ID | Query Description | Baseline Time (ms) | Post-Tuning Time (ms) | Absolute Gain (ms) | Performance Gain (%) | Speedup Factor |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **W1** | **Booking Conflict Check** | 6 | 0 | -6 ms | **100.0%** | **Instant (Sub-ms)** |
| **W2** | **Multi-Criteria Room Finder** | 196 | 64 | -132 ms | **67.3%** | **3.06x Faster** |
| **W3** | **Total Approved Hours per Space** | 32 | 15 | -17 ms | **53.1%** | **2.13x Faster** |
| **W4** | **Booking Density Heatmap** | 23 | 10 | -13 ms | **56.5%** | **2.30x Faster** |
| **W5** | **Maintenance Escalation Impact** | 17 | 3 | -14 ms | **82.4%** | **5.67x Faster** |

---

## 2. Deployed Non-Clustered & Filtered Index Inventory

The following non-clustered, covering, and filtered indexes were created in `outputs/15-index-tuning-G7.sql` to optimize query execution plans:

| Target Table | Index Name | Type | Filter Expression / Definition | Unique |
| :--- | :--- | :--- | :--- | :---: |
| `bookings` | `pk_bookings` | `CLUSTERED` | Primary Key | Yes |
| `bookings` | `ix_bookings_conflict_approved` | `NONCLUSTERED` | `([status] = 'approved')` | No |
| `bookings` | `ix_bookings_space_effective_covering` | `NONCLUSTERED` | `([status] IN ('approved', 'checked_in', 'completed', 'no_show'))` | No |
| `bookings` | `ix_bookings_status_semester_covering` | `NONCLUSTERED` | `([status] IN ('approved', 'checked_in', 'completed', 'no_show'))` | No |
| `bookings` | `ix_bookings_escalation_impact` | `NONCLUSTERED` | `([status] = 'approved')` | No |
| `maintenance_records` | `pk_maintenance_records` | `CLUSTERED` | Primary Key | Yes |
| `maintenance_records` | `ix_maintenance_open_covering` | `NONCLUSTERED` | `([status] IN ('reported', 'in_progress'))` | No |
| `space_facilities` | `pk_space_facilities` | `CLUSTERED` | Primary Key | Yes |
| `space_facilities` | `ix_space_facilities_facility_covering` | `NONCLUSTERED` | Covering index on `(facility_id, space_id)` | No |
| `spaces` | `pk_spaces` | `CLUSTERED` | Primary Key | Yes |
| `spaces` | `uq_spaces_building_floor_room` | `NONCLUSTERED` | Candidate Unique Key | Yes |
| `spaces` | `ix_spaces_capacity` | `NONCLUSTERED` | Index on `(capacity)` INCLUDE `(space_id)` | No |

---

## 3. Key Optimization Analysis Points for Report Generation

1. **W1 (Booking Conflict Check):**
   * **Gain:** Reduced execution time from 6 ms down to 0 ms (sub-millisecond).
   * **Optimization Strategy:** `ix_bookings_conflict_approved` isolates active `'approved'` bookings. Converts a full table/clustered scan into a targeted index seek on `(space_id, start_time, end_time)`.

2. **W2 (Multi-Criteria Room Finder):**
   * **Gain:** Reduced execution time from 196 ms to 64 ms (132 ms reduction, 3.06x speedup).
   * **Optimization Strategy:** Leverages `ix_spaces_capacity` for quick capacity filtering, `ix_space_facilities_facility_covering` for relational division (`HAVING COUNT = N`), and `ix_maintenance_open_covering` to rapidly exclude spaces under active out-of-service maintenance.

3. **W3 (Total Approved Booking Hours per Space):**
   * **Gain:** Reduced execution time from 32 ms to 15 ms (53.1% reduction).
   * **Optimization Strategy:** `ix_bookings_status_semester_covering` eliminates key lookups by providing a covering index over `(status, start_time, end_time, space_id)`.

4. **W4 (Booking Density Heatmap):**
   * **Gain:** Reduced execution time from 23 ms to 10 ms (56.5% reduction).
   * **Optimization Strategy:** `ix_bookings_space_effective_covering` allows fast aggregation over valid statuses without scanning cancelled or rejected rows.

5. **W5 (Maintenance Escalation Impact):**
   * **Gain:** Reduced execution time from 17 ms to 3 ms (82.4% reduction, 5.67x speedup).
   * **Optimization Strategy:** `ix_bookings_escalation_impact` seeks directly to approved bookings overlapping the specific escalated maintenance window on a given `space_id`.