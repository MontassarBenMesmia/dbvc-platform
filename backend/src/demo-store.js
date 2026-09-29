const migrations = Object.freeze([
  {
    version: '001',
    name: 'Create migration ledger',
    checksum: 'a9e4c3f1',
    status: 'applied',
    durationMs: 184
  },
  {
    version: '002',
    name: 'Create commerce schema',
    checksum: '4d82b96a',
    status: 'applied',
    durationMs: 672
  },
  {
    version: '003',
    name: 'Add order status index',
    checksum: 'f1160db7',
    status: 'pending',
    durationMs: null
  }
]);

const baseRun = Object.freeze({
  runId: 'demo-verify-1042',
  status: 'VERIFIED',
  startedAt: '2026-09-29T18:42:06Z',
  completedAt: '2026-09-29T18:42:08Z',
  migrationsChecked: 3,
  pendingMigrations: 1,
  rollbackVerified: true,
  durationMs: 1840
});

class DemoStore {
  constructor() {
    this.sequence = 1042;
    this.runs = [baseRun];
  }

  runVerification() {
    this.sequence += 1;
    const now = new Date();
    const completed = new Date(now.getTime() + 1260);
    const run = {
      runId: `demo-verify-${this.sequence}`,
      status: 'VERIFIED',
      startedAt: now.toISOString(),
      completedAt: completed.toISOString(),
      migrationsChecked: migrations.length,
      pendingMigrations: migrations.filter((item) => item.status === 'pending').length,
      rollbackVerified: true,
      durationMs: 1260
    };
    this.runs = [run, ...this.runs].slice(0, 5);
    return run;
  }

  dashboard() {
    return {
      mode: 'deterministic-demo',
      project: 'DBVC',
      version: '1.0.0',
      environment: 'SQL Server reference workspace',
      metrics: {
        migrationsTracked: migrations.length,
        pendingMigrations: migrations.filter((item) => item.status === 'pending').length,
        checksumCoverage: 100,
        rollbackCoverage: 100
      },
      pipeline: [
        { step: 1, name: 'Validate', detail: 'Check ordering, checksums, rollback pairs, and unsafe directives.' },
        { step: 2, name: 'Plan', detail: 'Build a signed manifest for the exact pending migration set.' },
        { step: 3, name: 'Verify', detail: 'Execute against the target inside a transaction, then roll back.' },
        { step: 4, name: 'Snapshot', detail: 'Create a recoverable database backup before mutation.' },
        { step: 5, name: 'Apply', detail: 'Acquire a lock, apply atomically, and record immutable evidence.' }
      ],
      migrations,
      recentRuns: this.runs,
      safeguards: [
        'Source and target identities must be explicit and different',
        'Only numbered, checksum-verified migrations enter a plan',
        'Every forward migration requires a rollback companion',
        'Verification always rolls back before an apply can be approved',
        'Public demo mode cannot connect to or mutate a database'
      ]
    };
  }
}

module.exports = { DemoStore, migrations };
