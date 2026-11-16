import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { env } from '../../src/config/env.config.js';

describe('Health & Diagnostic Endpoints', () => {
  const app = createApp();

  it('GET / returns 200 with status UP', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('success', true);
    expect(res.body.data).toHaveProperty('status', 'UP');
  });

  it('GET API_PREFIX returns service metadata', async () => {
    const res = await request(app).get(env.API_PREFIX);
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('success', true);
    expect(res.body.data).toHaveProperty('name', 'Simpex API');
    expect(res.body.data).toHaveProperty('version', '1.0.0');
  });

  it('GET /unknown-route returns 404 with structured error', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.status).toBe(404);
    expect(res.body).toHaveProperty('success', false);
    expect(res.body.error).toHaveProperty('code', 'NOT_FOUND');
  });
});
