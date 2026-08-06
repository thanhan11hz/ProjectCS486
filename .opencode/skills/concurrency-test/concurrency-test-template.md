# Output Folder Structure

The generated output should follow the folder structure below.

```text
outputs/13-concurrency-tests-G7/
    ├── data-init.sql
    ├── set-up-guide.md
    ├── <conflict-1>/
    │   ├── with-concurrency-enforcement/
    │   │   ├── procedure.sql
    │   │   ├── session-1.sql
    │   │   └── session-2.sql
    │   └── without-concurrency-enforcement/
    │       ├── procedure.sql
    │       ├── session-1.sql
    │       └── session-2.sql
    │
    ├── <conflict-2>/
    │   ├── with-concurrency-enforcement/
    │   │   ├── procedure.sql
    │   │   ├── session-1.sql
    │   │   └── session-2.sql
    │   └── without-concurrency-enforcement/
    │       ├── procedure.sql
    │       ├── session-1.sql
    │       └── session-2.sql
    │
    └── ...
```

## Folder Description

For each identified concurrency conflict, create a dedicated subfolder named after the conflict (for example, `double-booking`, `lost-update`, or `write-skew`).

Each conflict folder must contain two subfolders:

### `with-concurrency-enforcement/`

Contains the implementation that prevents the concurrency conflict.

| File | Description |
|------|-------------|
| `procedure.sql` | Stored procedure copied from `outputs/12-concurrency-implementation-G7.sql`. |
| `session-1.sql` | SQL script executed in Session 1 to simulate the concurrency scenario. |
| `session-2.sql` | SQL script executed in Session 2 to simulate the concurrency scenario. |

The two session scripts should:

- Invoke the stored procedure.
- Include appropriate `WAITFOR DELAY` statements so that both sessions overlap in execution.
- Demonstrate that the implemented concurrency control successfully prevents the target concurrency conflict.

---

### `without-concurrency-enforcement/`

Contains the same implementation with all concurrency control mechanisms removed.

| File | Description |
|------|-------------|
| `procedure.sql` | Copy of the stored procedure with all isolation levels and locking hints removed. |
| `session-1.sql` | SQL script executed in Session 1. |
| `session-2.sql` | SQL script executed in Session 2. |

The two session scripts should:

- Invoke the modified stored procedure.
- Include appropriate `WAITFOR DELAY` statements so that both sessions overlap in execution.
- Demonstrate that the intended concurrency conflict occurs due to the absence of concurrency control.
