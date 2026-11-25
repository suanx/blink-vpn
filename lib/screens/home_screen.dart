import 'package:flutter/material.dart';
import '../services/psiphon_service.dart';
import '../services/vpn_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.service});
  final VpnService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blink VPN'),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) => SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(service.currentNode?.name ?? '未选择节点', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  if (service.isConnected) {
                    service.disconnect();
                  } else {
                    service.connect();
                  }
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
                  ),
                  child: Center(
                    child: Text(
                      service.isConnecting ? '连接中...' : service.isConnected ? '已连接' : '点击连接',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('速度：${service.lastSpeedMbps.toStringAsFixed(1)} Mbps', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              // Psiphon 应急模式（代理模式，第 1 阶段）：仅应用内使用，不是全设备 VPN。
              SwitchListTile(
                title: const Text('应急模式 (Psiphon)', style: TextStyle(fontSize: 13)),
                subtitle: const Text('代理模式，仅应用内使用，不是全设备 VPN',
                    style: TextStyle(fontSize: 11)),
                value: service.emergencyMode,
                onChanged: service.setEmergencyMode,
              ),
              Text(
                _psiphonStatusText(service),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: service.psiphon.isConnected
                    ? service.disconnectEmergency
                    : service.connectEmergency,
                child: Text(
                  service.psiphon.isConnected ? '断开应急连接' : '应急连接',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '应急模式为代理模式，速度约 15–22 Mbps，单 IP 最多 3 条隧道，节点会轮换。\n需先向 Psiphon Inc. 申请 Blink 自己的 SponsorId，见 psiphon_config.json。',
                style: TextStyle(fontSize: 11, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String _psiphonStatusText(VpnService service) {
    final p = service.psiphon;
    switch (p.state) {
      case PsiphonState.connecting:
        return '应急：连接中…';
      case PsiphonState.connected:
        return '应急：已连接（SOCKS ${_getSocks(p)}，出口 IP ${p.exitIp.isEmpty ? '未检测' : p.exitIp}）';
      case PsiphonState.error:
        return '应急：出错 ${p.lastError}';
      case PsiphonState.idle:
        return '应急：未连接';
    }
  }

  String _getSocks(PsiphonService p) =>
      p.socksPort == 0 ? '—' : '127.0.0.1:${p.socksPort}';
}
