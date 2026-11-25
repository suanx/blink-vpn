export interface User {
  id: string;
  email: string;
  salt: string;
  password_hash: string;
  plan: string;
  created_at: string;
}

export async function ensureSchema(db: D1Database): Promise<void> {
  // Single-line statement via prepare().run(): D1 exec() chokes on
  // multi-line SQL (it only runs the first line and reports "incomplete input").
  await db
    .prepare(
      "CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, salt TEXT NOT NULL, password_hash TEXT NOT NULL, plan TEXT NOT NULL DEFAULT 'free', created_at TEXT NOT NULL)",
    )
    .run();
}

export async function getUserByEmail(db: D1Database, email: string): Promise<User | null> {
  return await db.prepare('SELECT * FROM users WHERE email = ?').bind(email).first<User>();
}

export async function createUser(db: D1Database, user: User): Promise<void> {
  await db
    .prepare('INSERT INTO users (id, email, salt, password_hash, plan, created_at) VALUES (?, ?, ?, ?, ?, ?)')
    .bind(user.id, user.email, user.salt, user.password_hash, user.plan, user.created_at)
    .run();
}
