# Concurrency Design

## 1. Overview
(Provide a brief overview of the overall concurrency control strategy for the database system.)

## 2. Conflict Handling

### 2.1 Conflict CC-01: Instant Booking Overlap
* **Scenario:** (Describe the concurrent scenario)
* **Shared Resource:** (What business resource is being contended)
* **Business Rule Protected:** (List relevant BRs, e.g., BR-14, BR-50)
* **Chosen Mechanism:** (Specific SQL Server isolation level, locking hint, etc.)
* **Implementation Pseudo-code:**
```sql
BEGIN TRAN;
-- Describe lock acquisition and checks here
COMMIT TRAN;
```
* **Justification:** (Explain why this specific mechanism is correct, safe, and optimal for this scenario)

### 2.2 Conflict CC-02: Approval vs. Instant Booking Overlap
* **Scenario:** 
* **Shared Resource:** 
* **Business Rule Protected:** 
* **Chosen Mechanism:** 
* **Implementation Pseudo-code:**
```sql
BEGIN TRAN;
-- ...
COMMIT TRAN;
```
* **Justification:** 

### 2.3 Conflict CC-03: Escalation vs. Booking Creation
* **Scenario:** 
* **Shared Resource:** 
* **Business Rule Protected:** 
* **Chosen Mechanism:** 
* **Implementation Pseudo-code:**
```sql
BEGIN TRAN;
-- ...
COMMIT TRAN;
```
* **Justification:** 

### 2.4 Conflict CC-04: Advisory Notification Miss
* **Scenario:** 
* **Shared Resource:** 
* **Business Rule Protected:** 
* **Chosen Mechanism:** 
* **Implementation Pseudo-code:**
```sql
BEGIN TRAN;
-- ...
COMMIT TRAN;
```
* **Justification:** 

### 2.5 Conflict CC-05: Concurrent Maintenance State Updates
* **Scenario:** 
* **Shared Resource:** 
* **Business Rule Protected:** 
* **Chosen Mechanism:** 
* **Implementation Pseudo-code:**
```sql
BEGIN TRAN;
-- ...
COMMIT TRAN;
```
* **Justification:** 

## 3. Summary
(Summarize how the combination of these mechanisms ensures complete data consistency without severe performance degradation.)
