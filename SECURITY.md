# Security

DBVC's hosted demo is deliberately unable to connect to a database or execute local commands. Real SQL Server operations are available only through the local PowerShell engine.

- Never commit `.env`, SQL credentials, backups, exported data, or generated artifacts.
- `Apply` requires `DBVC_ALLOW_DATABASE_WRITES=true` and an explicit backup path.
- The engine rejects gaps, missing rollback companions, unsupported filenames, and migrations containing `USE`.
- Report vulnerabilities privately to the repository owner instead of opening a public issue.
