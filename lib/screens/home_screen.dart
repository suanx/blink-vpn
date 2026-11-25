import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.service});
  final VpnService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blink VPN')),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(service.currentNode?.name ?? 'No node selected', style: TextStyle(fontSize: 13)),
              SizedBox(height: 24),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
                  ),
                  child: Center(
                    child: Text(
                      service.isConnecting ? 'Connecting...' : service.isConnected ? 'Connected' : 'Tap to Connect',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('Speed: ${service.lastSpeedMbps.toStringAsFixed(1)} Mbps', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
