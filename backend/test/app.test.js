const assert = require('node:assert/strict');
const test = require('node:test');
const { createApp } = require('../src/app');

async function withServer(callback) {
  const server = createApp({ publicDirectory: __dirname }).listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const address = server.address();
  try {
    await callback(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('health and dashboard expose a safe deterministic demo', async () => {
  await withServer(async (baseUrl) => {
    const healthResponse = await fetch(`${baseUrl}/api/v1/health`);
    const health = await healthResponse.json();
    assert.equal(healthResponse.status, 200);
    assert.equal(health.status, 'ok');

    const dashboard = await (await fetch(`${baseUrl}/api/v1/dashboard`)).json();
    assert.equal(dashboard.mode, 'deterministic-demo');
    assert.equal(dashboard.metrics.checksumCoverage, 100);
    assert.equal(dashboard.migrations.length, 3);
    assert.equal(JSON.stringify(dashboard).includes('production credential'), false);
  });
});

test('verification creates a bounded in-memory evidence record', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/v1/demo/verify`, { method: 'POST' });
    const run = await response.json();
    assert.equal(response.status, 201);
    assert.equal(run.status, 'VERIFIED');
    assert.equal(run.rollbackVerified, true);
    assert.equal(run.pendingMigrations, 1);
  });
});

test('arbitrary execution and administrative routes do not exist', async () => {
  await withServer(async (baseUrl) => {
    assert.equal((await fetch(`${baseUrl}/api/commands`, { method: 'POST' })).status, 404);
    assert.equal((await fetch(`${baseUrl}/api/admin/execute`, { method: 'POST' })).status, 404);
  });
});
