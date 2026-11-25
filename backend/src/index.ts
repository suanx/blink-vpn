import { handleRegister, handleLogin, json, type Env } from './routes-auth';
import { handleMe, handleConfig, handleProtocols } from './routes-user';
import { NODES } from './nodes';
import { ensureSchema } from './db';

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname;

    if (req.method === 'GET' && path === '/api/health') return json({ ok: true });
    if (req.method === 'GET' && path === '/api/nodes') return json({ nodes: NODES });
    if (req.method === 'GET' && path === '/api/protocols') return handleProtocols();

    // All routes below touch the users table; make sure it exists first.
    if (path.startsWith('/api/auth') || path === '/api/me' || path === '/api/config') {
      await ensureSchema(env.DB);
    }

    if (req.method === 'POST' && path === '/api/auth/register') return handleRegister(req, env);
    if (req.method === 'POST' && path === '/api/auth/login') return handleLogin(req, env);
    if (req.method === 'GET' && path === '/api/me') return handleMe(req, env);
    if (req.method === 'GET' && path === '/api/config') return handleConfig(req, env);

    return json({ error: 'not_found' }, 404);
  },
};
