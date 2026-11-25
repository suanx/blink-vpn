import 'package:flutter/material.dart';
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
        builder: (context, _) => Center(
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
            ],
          ),
        ),
      ),
    );
  }
}
