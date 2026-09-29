# Migration contract

| Rule | Enforcement |
| --- | --- |
| Filename | `NNN_descriptive_name.up.sql` |
| Rollback | Matching `NNN_descriptive_name.down.sql` is mandatory |
| Ordering | Three-digit versions are unique and contiguous from `001` |
| Integrity | Forward and rollback SHA-256 hashes are recorded in the plan |
| Target selection | Database comes from the runner; migrations cannot contain `USE` |
| Verification | All planned SQL executes inside a transaction that ends in `ROLLBACK` |
| Apply authorization | Requires `DBVC_ALLOW_DATABASE_WRITES=true` |
| Recovery | Apply requires an explicit SQL Server backup destination |
| Evidence | Plan JSON, console output, backup, and schema ledger form the audit trail |

The fictional commerce schema exists only to exercise foreign keys, composite keys, checks, indexes, and rollback ordering.
