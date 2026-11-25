import { hashPassword, makeSalt, signToken } from './auth';
import { getUserByEmail, createUser, type User } from './db';

export interface Env {
  DB: D1Database;
  TOKEN_SECRET: string;
}

export const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { 'Content-Type': 'application/json' } });

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

async function readBody(req: Request): Promise<Record<string, unknown> | null> {
  try {
    return (await req.json()) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export async function handleRegister(req: Request, env: Env): Promise<Response> {
  const body = await readBody(req);
  const email = body?.email;
  const password = body?.password;
  if (typeof email !== 'string' || !emailRegex.test(email) || typeof password !== 'string' || password.length < 8) {
    return json({ error: 'bad_input' }, 400);
  }
  if (await getUserByEmail(env.DB, email)) return json({ error: 'duplicate_email' }, 409);
  const salt = await makeSalt();
  const user: User = {
    id: crypto.randomUUID(),
    email,
    salt,
    password_hash: await hashPassword(password, salt),
    plan: 'free',
    created_at: new Date().toISOString(),
  };
  await createUser(env.DB, user);
  return json({ id: user.id, email: user.email, plan: user.plan }, 201);
}

export async function handleLogin(req: Request, env: Env): Promise<Response> {
  if (!env.TOKEN_SECRET) return json({ error: 'server_misconfigured' }, 500);
  const body = await readBody(req);
  const email = body?.email;
  const password = body?.password;
  if (typeof email !== 'string' || typeof password !== 'string') return json({ error: 'bad_input' }, 400);
  const user = await getUserByEmail(env.DB, email);
  if (!user) return json({ error: 'invalid_credentials' }, 401);
  const hash = await hashPassword(password, user.salt);
  if (hash !== user.password_hash) return json({ error: 'invalid_credentials' }, 401);
  const token = await signToken(
    { sub: user.id, email: user.email, exp: Math.floor(Date.now() / 1000) + 30 * 24 * 3600 },
    env.TOKEN_SECRET,
  );
  return json({ token, email: user.email, plan: user.plan });
}
