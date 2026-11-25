const enc = new TextEncoder();

function bufToHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function toB64Url(buf: ArrayBufferLike): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function fromB64Url(s: string): ArrayBuffer {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - (s.length % 4)) % 4);
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

export async function makeSalt(): Promise<string> {
  const buf = crypto.getRandomValues(new Uint8Array(16));
  return bufToHex(buf.buffer);
}

export async function hashPassword(pw: string, salt: string): Promise<string> {
  const data = enc.encode(salt + ':' + pw);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return bufToHex(digest);
}

export async function signToken(payload: Record<string, unknown>, secret: string): Promise<string> {
  const payloadB64 = toB64Url(enc.encode(JSON.stringify(payload)).buffer);
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(payloadB64));
  return payloadB64 + '.' + toB64Url(sig);
}

export async function verifyToken(token: string, secret: string): Promise<Record<string, unknown> | null> {
  const [payloadB64, sigB64] = token.split('.');
  if (!payloadB64 || !sigB64) return null;
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('HMAC', key, fromB64Url(sigB64), enc.encode(payloadB64));
  if (!ok) return null;
  try {
    const payload = JSON.parse(new TextDecoder().decode(fromB64Url(payloadB64))) as Record<string, unknown>;
    if (typeof payload.exp !== 'number' || payload.exp * 1000 < Date.now()) return null;
    return payload;
  } catch {
    return null;
  }
}

// Deterministic per-user Shadowsocks password derived from the user's UUID.
// No shared password, nothing hardcoded in git.
export async function deriveSsPassword(uuid: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', enc.encode(uuid + ':shadowsocks'));
  return toB64Url(digest).slice(0, 32);
}
