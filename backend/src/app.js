const path = require('node:path');
const express = require('express');
const helmet = require('helmet');
const { DemoStore, migrations } = require('./demo-store');

function createApp(options = {}) {
  const app = express();
  const store = options.store || new DemoStore();
  const publicDirectory = options.publicDirectory || path.resolve(__dirname, '..', 'public');

  app.disable('x-powered-by');
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", 'data:'],
        connectSrc: ["'self'"],
        objectSrc: ["'none'"],
        frameAncestors: ["'none'"]
      }
    },
    crossOriginEmbedderPolicy: false
  }));
  app.use(express.json({ limit: '32kb' }));

  app.get('/api/v1/health', (_request, response) => {
    response.json({ status: 'ok', service: 'dbvc-api', version: '1.0.0', mode: 'demo' });
  });

  app.get('/api/v1/dashboard', (_request, response) => {
    response.json(store.dashboard());
  });

  app.get('/api/v1/migrations', (_request, response) => {
    response.json({ count: migrations.length, migrations });
  });

  app.post('/api/v1/demo/verify', (_request, response) => {
    response.status(201).json(store.runVerification());
  });

  app.get('/api/v1/architecture', (_request, response) => {
    response.json({
      local: ['Angular dashboard', 'Node.js allowlisted API', 'PowerShell migration engine', 'SQL Server'],
      aws: ['CloudFront + S3', 'Cognito', 'Application Load Balancer', 'ECS API + worker', 'SQS', 'Secrets Manager', 'S3 evidence vault', 'DynamoDB locks', 'RDS for SQL Server', 'CloudWatch + CloudTrail']
    });
  });

  app.get('/api/openapi', (request, response) => {
    const origin = `${request.protocol}://${request.get('host')}`;
    response.json({
      openapi: '3.1.0',
      info: { title: 'DBVC API', version: '1.0.0', description: 'Read-only portfolio demo API for a guarded SQL Server migration workflow.' },
      servers: [{ url: origin }],
      paths: {
        '/api/v1/health': { get: { summary: 'Service health', responses: { 200: { description: 'Healthy' } } } },
        '/api/v1/dashboard': { get: { summary: 'Dashboard state', responses: { 200: { description: 'Current demo state' } } } },
        '/api/v1/migrations': { get: { summary: 'Migration catalog', responses: { 200: { description: 'Versioned migrations' } } } },
        '/api/v1/demo/verify': { post: { summary: 'Run deterministic verification demo', responses: { 201: { description: 'Verification completed' } } } }
      }
    });
  });

  app.use(express.static(publicDirectory, { index: false, maxAge: '1h' }));
  app.get(/^(?!\/api(?:\/|$)).*/, (_request, response) => {
    response.sendFile(path.join(publicDirectory, 'index.html'));
  });

  app.use((error, _request, response, _next) => {
    response.status(500).json({ code: 'INTERNAL_ERROR', message: 'The request could not be completed.' });
  });

  return app;
}

module.exports = { createApp };
