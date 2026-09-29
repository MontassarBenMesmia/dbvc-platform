import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';

interface MigrationRecord {
  version: string;
  name: string;
  checksum: string;
  status: 'applied' | 'pending';
  durationMs: number | null;
}

interface VerificationRun {
  runId: string;
  status: 'VERIFIED';
  startedAt: string;
  completedAt: string;
  migrationsChecked: number;
  pendingMigrations: number;
  rollbackVerified: boolean;
  durationMs: number;
}

interface Dashboard {
  mode: string;
  project: string;
  version: string;
  environment: string;
  metrics: { migrationsTracked: number; pendingMigrations: number; checksumCoverage: number; rollbackCoverage: number };
  pipeline: Array<{ step: number; name: string; detail: string }>;
  migrations: MigrationRecord[];
  recentRuns: VerificationRun[];
  safeguards: string[];
}

@Component({
  selector: 'app-root',
  imports: [CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private readonly http = inject(HttpClient);
  private readonly changeDetector = inject(ChangeDetectorRef);
  dashboard: Dashboard | null = null;
  running = false;
  errorMessage = '';

  get latestRun(): VerificationRun | null { return this.dashboard?.recentRuns[0] ?? null; }

  ngOnInit(): void { this.loadDashboard(); }

  loadDashboard(): void {
    this.errorMessage = '';
    this.http.get<Dashboard>('/api/v1/dashboard').subscribe({
      next: (dashboard) => { this.dashboard = dashboard; this.changeDetector.markForCheck(); },
      error: () => { this.dashboard = null; this.errorMessage = 'The demo API is unavailable.'; this.changeDetector.markForCheck(); }
    });
  }

  runVerification(): void {
    if (this.running || !this.dashboard) return;
    this.running = true;
    this.changeDetector.markForCheck();
    this.http.post<VerificationRun>('/api/v1/demo/verify', {}).subscribe({
      next: (run) => {
        this.dashboard = { ...this.dashboard!, recentRuns: [run, ...this.dashboard!.recentRuns].slice(0, 5) };
        this.running = false;
        this.changeDetector.markForCheck();
      },
      error: () => { this.running = false; this.errorMessage = 'Verification could not be completed.'; this.changeDetector.markForCheck(); }
    });
  }

  pipelineIcon(step: number): string { return ['✓', '≡', '↺', '◇', '→'][step - 1] ?? '•'; }
}
