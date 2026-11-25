# Blink VPN 后端

Cloudflare Workers + D1，管用户、节点、套餐和多协议配置。

## 接口（全部返回 JSON）

- `GET /api/health` → `{ok:true}`
- `GET /api/nodes` → 4 个节点（香港 / 日本 / 新加坡 / 美国），含支持的协议
- `GET /api/protocols` → 支持的协议：vless、trojan、shadowsocks
- `POST /api/auth/register` `{email, password}` → 邮箱格式校验，密码 ≥ 8 位，SHA-256 + 盐存储，返回用户 UUID
- `POST /api/auth/login` `{email, password}` → 返回 HMAC-SHA256 签名 token，30 天有效
- `GET /api/me`（Bearer token）→ 邮箱、注册时间、套餐 free
- `GET /api/config?node=hk&protocol=vless`（Bearer token）→ sing-box 兼容的 outbound 配置

协议说明：VLESS 用用户 UUID；Trojan 用 UUID 做密码；Shadowsocks 用 `aes-256-gcm`，密码由用户 UUID 派生（每个用户不同，不共用密码）。

WireGuard 暂未接入：它需要真实的服务端密钥对和 WG 服务端，不是光一个配置能解决的。

## 注意

- 登录是邮箱 + 密码，不发验证码邮件（没有 SMTP / 邮件服务）。
- Token 签名密钥是 Worker secret `TOKEN_SECRET`，用 `wrangler secret put TOKEN_SECRET` 设置，不要写进代码或 git。
- 真实隧道（VLESS-over-WebSocket 代理）和 Flutter 客户端的 sing-box 接入不在这一步。

## 部署

```bash
export CLOUDFLARE_API_TOKEN="$(python3 ~/workspace/custom-connectors/custom.cloudflare-api/bin/cf.py surrogate)"
export CLOUDFLARE_ACCOUNT_ID=c07323a615cdcd49d596ef980ea7ac4d
npx wrangler d1 create blink-vpn-db   # 把返回的 database_id 填进 wrangler.toml
npx wrangler secret put TOKEN_SECRET
npx wrangler deploy
```
