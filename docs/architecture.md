# Architecture and trust boundaries

DBVC intentionally separates presentation, orchestration, execution, and evidence.

1. The Angular dashboard visualizes plans and the deterministic public demonstration.
2. The Express API exposes bounded JSON resources. It cannot accept arbitrary shell commands or SQL.
3. The PowerShell engine is a local/operator component. It validates repository files before invoking `sqlcmd` with argument arrays.
4. SQL Server is the mutation boundary. Verify uses one connection and rolls back; Apply requires explicit write enablement and a successful backup.
5. Git stores human-reviewed migration and rollback files. Generated manifests and backups never enter Git.

The hosted application includes only layers 1 and 2 in demo mode. This makes it useful to reviewers without creating a public database-administration surface.
