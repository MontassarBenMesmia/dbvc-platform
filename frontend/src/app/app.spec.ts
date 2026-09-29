import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [App], providers: [provideHttpClient(), provideHttpClientTesting()] }).compileComponents();
  });

  it('renders live dashboard data from the API', async () => {
    const fixture = TestBed.createComponent(App);
    const http = TestBed.inject(HttpTestingController);
    fixture.detectChanges();
    const dashboard = {
      mode: 'deterministic-demo', project: 'DBVC', version: '1.0.0', environment: 'SQL Server reference workspace',
      metrics: { migrationsTracked: 3, pendingMigrations: 1, checksumCoverage: 100, rollbackCoverage: 100 },
      pipeline: [{ step: 1, name: 'Validate', detail: 'Validate migrations' }],
      migrations: [{ version: '001', name: 'Create ledger', checksum: 'abcdef12', status: 'applied', durationMs: 10 }],
      recentRuns: [{ runId: 'demo-1', status: 'VERIFIED', startedAt: '', completedAt: '', migrationsChecked: 3, pendingMigrations: 1, rollbackVerified: true, durationMs: 20 }],
      safeguards: ['No arbitrary SQL']
    };
    http.expectOne('/api/v1/dashboard').flush(dashboard);
    expect(fixture.componentInstance.dashboard).not.toBeNull();
    await fixture.whenStable();
    fixture.detectChanges();
    const heading = fixture.nativeElement.querySelector('h1');
    expect(heading).not.toBeNull();
    expect(heading.textContent).toContain('Ship database changes');
    expect(fixture.nativeElement.textContent).toContain('Create ledger');
    http.verify();
  });
});
