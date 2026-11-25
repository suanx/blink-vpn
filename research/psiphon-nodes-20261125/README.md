# Psiphon 节点整理 — 2026-11-25（研究资料，未接入 Blink 后端）

## 来源

- APK：Sato 2026-11-25 发来的官方 Psiphon Android APK（40 MB，`PsiphonAndroid_0_7a88.apk`），不是 511 Mod。
  内嵌节点不在 `res/raw/psiphon_embedded_servers`，而在资源混淆后的 `res/MN`（1,084,121 字节），格式相同，解析 400 条，0 失败。
- 远程列表：`https://s3.amazonaws.com/psiphon/web/iohq-waa4-q4dt/server_list_compressed`，2026-11-25 20:29 拉到 480 条。
- 合并去重：871 条，重叠仅 9 个 IP。

## 文件

- `all_entries_merged.json` — 合并 871 条完整版（含 ssh 凭证），1.2 MB
- `all_entries_merged.public.json` — 脱敏版，只有 IP / 地区 / 端口 / 能力
- `serverlist_for_client_merged.txt` — ConsoleClient `-serverList` 用的 hex 格式
- `entries_embedded_only.json` — 仅 APK 内嵌 400 条完整版

合并后地区：US 179 / CA 116 / DE 93 / GB 82 / NL 57 / FR 42 / SE 36 / RS 30 / IN 28 / ES 25。

## 状态：未接入 Blink，不能直接当节点用

这 871 条**没有写进 Blink 后端**（`backend/` 的 `/api/nodes` / `/api/config` 未改动），也没有写进 Flutter 客户端。原因有四条，都是实测结论，不是推测：

1. **协议不对**：Psiphon 节点是 OSSH / meek / QUIC，不是 VLESS / Trojan / Shadowsocks。Blink 后端下发的是 VLESS 等配置，sing-box 客户端连不上 Psiphon 节点。要用必须在客户端里嵌官方 psiphon-tunnel-core（Go），再走本地 SOCKS5，那是另一套客户端架构，不是加个节点列表就能解决的。
2. **单 IP 只有 3 条隧道**：lza6 的实测结论，同一公网 IP 服务端只允许 3 条隧道，40 个实例只有 1 个活下来。Blink 是多用户产品，后端如果集中跑这批节点，3 条隧道就是全站天花板。
3. **速度低**：3 条隧道聚合才 15–22 Mbps，单连接约 5–7 Mbps，16 并发以内 p50 0.65–1.5s，32 并发 p95 30 秒以上。
4. **合规**：Psiphon 是为受审查地区用户提供的人权工具，作者原话是不要把节点接进生产代理池，会违反 ToS 且挤占真实用户带宽。节点还会定期轮换，这份 2026-11-25 的快照会过期。

## 如果以后要走合法路线

- 不要把这批节点当 Blink 自有节点下发。
- 可行的方向只有客户端侧嵌官方 tunnel-core 当“应急模式”，每个用户自己直连 Psiphon，相当于官方 App 的能力，不是 Blink 在后端分发 Psiphon 带宽。那需要单独评估 Flutter + Go 的集成工作量。
- 否则 Blink 的节点还是走自己的 VLESS-over-WebSocket 隧道（后端已有的 `/api/config` 方向）。

## Phase 1：Psiphon 应急模式（代理模式）— 2026-11-25 已接入客户端

Sato 选了客户端侧嵌官方 tunnel-core 当应急模式。已做的工作（在 `~/workspace/blink-vpn/app/`，与 GitHub `suanx/blink-vpn` 同步）：

- 官方 MobileLibrary AAR `ca.psiphon:psiphontunnel:2.0.43`（maven-metadata 验证为最新，lastUpdated 20261117181723），Maven 仓库加在 `android/build.gradle`，依赖加在 `android/app/build.gradle`。没有在本地编译 Go。
- `lib/services/psiphon_service.dart`（新）：MethodChannel `blink_vpn/psiphon`，状态 idle/connecting/connected/error，SOCKS/HTTP 端口，出口 IP 检测（经 SOCKS5 查 api.ipify.org）。
- `android/app/src/main/kotlin/com/blinkvpn/app/MainActivity.kt`：直接调用 AAR 里的 `psi.Psi.start/stop`（gomobile 绑定），自写 `PsiphonProvider` 实现；通知类型按 `psiphon/notice.go` 核对（Tunnels / ListeningSocksProxyPort / ListeningHttpProxyPort / ClientRegion / ConnectedServerRegion / EstablishTunnelTimeout）。启动在后台线程跑，`stop()` 会阻塞数秒。
- `android/app/src/main/res/raw/psiphon_config.json`：只有占位值，见下。
- `assets/psiphon_serverlist.txt`：871 条合并 serverlist（hex 行），Kotlin 侧从 assets 读出当 `embeddedServerEntryList` 传给 `Psi.start`，不走 MethodChannel 传 2.3 MB。
- 首页加了“应急模式 (Psiphon)”开关 + 状态 + 应急连接/断开按钮，`VpnService` 里接了 `psiphon` 服务。

**代码来源**：Kilo `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` 起草（psiphon_service.dart、MainActivity.kt、vpn_service/home_screen 改动三份草稿），Bike 审阅后重写/修正。Runcrate GLM-5.3-Flash 和 DeepSeek V4.1 Flash 试过：推理 token 占满 max_tokens，返回内容为空，不可用。Kilo 草稿的问题已在审阅中修正：Dart 草稿把 start/stop 当入站调用且用了不存在的 ProxySettings API；Kotlin 草稿用了不存在的 `getHttpProxyPort()` / `tunnel.connected`、start 后立即报成功、每次回调新建 MethodChannel、未调 `super.configureFlutterEngine`；第二份 Dart 草稿改写了现有 VpnService/HomeScreen 的类型与布局（currentNode 变 String、测速写死 15.0），已弃用，改为对原文件做最小手术式修改。

**未复制上游 PsiphonTunnel.java**：那份文件在本次任务中被执行风险检查拦截，不能直接复制进仓库。MainActivity 改为直接调用 `psi.Psi`，功能等价但未经官方 wrapper 验证，是本次 CI 最大的不确定点。

**BLOCKER — SponsorId**：`psiphon_config.json` 里的 `PropagationChannelId`、`SponsorId`、`RemoteServerListSignaturePublicKey` 都是占位值。必须是 Blink 自己向 Psiphon Inc. 申请的值，占位值下隧道会启动失败。**绝对不要**把官方 Psiphon App 的值（APK `res/UD` 里的那套）复制进来，那是冒充官方应用。

**仍未做（第 2 阶段）**：全设备 VPN（VpnService + tun2socks 全设备路由）。第 1 阶段只是本机代理，应用内流量可走代理，其他 App 的流量不走。3 条隧道上限、15–22 Mbps、节点轮换、ToS 说明仍适用。
