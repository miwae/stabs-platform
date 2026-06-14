const request = require('supertest');
const app = require('../server');

describe('API Health & Authentication', () => {
  
  test('GET /health should return ok status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
    expect(response.body.timestamp).toBeDefined();
  });

  test('POST /auth/login should return JWT token', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({});
    
    expect(response.status).toBe(200);
    expect(response.body.token).toBeDefined();
    expect(response.body.token.split('.')).toHaveLength(3); // JWT format
  });

  test('GET /api/health without token should return 401', async () => {
    const response = await request(app).get('/api/health');
    expect(response.status).toBe(401);
  });

  test('GET /api/health with valid token should return ok', async () => {
    // Get token first
    const loginRes = await request(app).post('/auth/login');
    const token = loginRes.body.token;

    // Use token
    const response = await request(app)
      .get('/api/health')
      .set('Authorization', `Bearer ${token}`);
    
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('authenticated');
    expect(response.body.user_id).toBe('demo-user');
  });
});

describe('Document Upload', () => {
  
  let token;

  beforeAll(async () => {
    const res = await request(app).post('/auth/login');
    token = res.body.token;
  });

  test('POST /api/documents/upload should accept image data', async () => {
    const response = await request(app)
      .post('/api/documents/upload')
      .set('Authorization', `Bearer ${token}`)
      .send({
        file_data: 'base64encodedimagdata',
        file_name: 'test-document.jpg'
      });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.status).toBe('processing');
  });

  test('POST /api/documents/upload without file_data should fail', async () => {
    const response = await request(app)
      .post('/api/documents/upload')
      .set('Authorization', `Bearer ${token}`)
      .send({ file_name: 'test.jpg' });
    
    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
  });
});

describe('Document Extraction', () => {
  
  let token;

  beforeAll(async () => {
    const res = await request(app).post('/auth/login');
    token = res.body.token;
  });

  test('POST /api/documents/extract should return extracted data', async () => {
    const response = await request(app)
      .post('/api/documents/extract')
      .set('Authorization', `Bearer ${token}`)
      .send({ document_id: 'test-doc-123' });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.extracted_data).toBeDefined();
    expect(response.body.extracted_data.firstName).toBeDefined();
  });
});

describe('Error Handling', () => {
  
  test('Invalid JSON should return 400', async () => {
    const response = await request(app)
      .post('/api/documents/upload')
      .set('Content-Type', 'application/json')
      .send('invalid json {');
    
    expect([400, 404]).toContain(response.status);
  });
});
