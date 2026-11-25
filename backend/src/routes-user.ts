import { NODES, findNode } from './nodes';
import { verifyToken, deriveSsPassword } from './auth';
import { json, type Env } from './routes-auth';
import { getUserByEmail } from './db';

export const PROTOCOLS = [
  { id: 'vless', name: 'VLESS', transport: 'WebSocket + TLS', nodes: NODES.filter((n) => n.protocols.includes('vless')).map((n) => n.id) },
  { id: 'trojan', name: 'Trojan', transport: 'TLS', nodes: NODES.filter((n) => n.protocols.includes('trojan')).map((n) => n.id) },
  { id: 'shadowsocks', name: 'Shadowsocks', transport: 'aes-256-gcm', nodes: NODES.filter((n) => n.protocols.includes('shadowsocks')).map((n) => n.id) },
];

export function handleProtocols(): Response {
  return json({ protocols: PROTOCOLS });
}

async function authedUser(req: Request, env: Env) {
  const auth = req.headers.get('Authorization');
  if (!auth || !auth.startsWith('Bearer ')) return null;
  const payload = await verifyToken(auth.slice(7), env.TOKEN_SECRET);
  if (!payload || typeof payload.email !== 'string' || typeof payload.sub !== 'string') return null;
  const user = await getUserByEmail(env.DB, payload.email);
  if (!user) return null;
  return { user, uuid: payload.sub as string };
}

export async function handleMe(req: Request, env: Env): Promise<Response> {
  const authed = await authedUser(req, env);
  if (!authed) return json({ error: 'invalid_token' }, 401);
  const { user } = authed;
  return json({ email: user.email, plan: user.plan, created_at: user.created_at });
}

export async function handleConfig(req: Request, env: Env): Promise<Response> {
  const authed = await authedUser(req, env);
  if (!authed) return json({ error: 'invalid_token' }, 401);
  const { uuid } = authed;
  const url = new URL(req.url);
  const nodeId = url.searchParams.get('node') || 'hk';
  const protocol = url.searchParams.get('protocol') || 'vless';
  const n = findNode(nodeId);
  if (!n) return json({ error: 'unknown_node' }, 404);
  if (!n.protocols.includes(protocol)) return json({ error: 'unsupported_protocol' }, 400);

  let outbound: Record<string, unknown>;
  if (protocol === 'vless') {
    outbound = {
      type: 'vless',
      tag: `blink-${n.id}`,
      server: n.address,
      server_port: 443,
      uuid,
      flow: '',
      tls: { enabled: true, server_name: n.address },
      transport: { type: 'ws', path: n.wsPath, headers: { Host: n.address } },
    };
  } else if (protocol === 'trojan') {
    outbound = {
      type: 'trojan',
      tag: `blink-${n.id}`,
      server: n.address,
      server_port: 443,
      password: uuid,
      tls: { enabled: true, server_name: n.address },
      transport: { type: 'ws', path: n.wsPath, headers: { Host: n.address } },
    };
  } else {
    outbound = {
      type: 'shadowsocks',
      tag: `blink-${n.id}`,
      server: n.address,
      server_port: 443,
      method: 'aes-256-gcm',
      password: await deriveSsPassword(uuid),
    };
  }
  return json({ protocol, node: n.id, outbound });
}
