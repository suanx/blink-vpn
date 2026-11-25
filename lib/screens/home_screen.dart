import 'dart:math';

import 'package:flutter/material.dart';

import '../services/vpn_service.dart';
import 'nodes_screen.dart';
import 'speed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
  });

  final VpnService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    widget.service.addListener(_syncPulse);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.service.isConnecting && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.service.isConnecting && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_syncPulse);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    final service = widget.service;
    if (service.isConnecting) return;
    if (service.isConnected) {
      service.disconnect();
    } else {
      await service.connect();
    }
  }

  void _openNodes() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NodesScreen(service: widget.service),
      ),
    );
  }

  Future<void> _reconnect() async {
    final service = widget.service;
    if (service.isConnecting) return;
    if (service.isConnected) {
      service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await service.connect();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orbSize = min(screenWidth * 0.62, 280.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Blink VPN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleConnection,
                    child: AnimatedBuilder(
                      animation: service,
                      builder: (context, _) {
                        Widget orb = Container(
                          width: orbSize,
                          height: orbSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.blue, Colors.cyan],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        );
                        if (service.isConnecting) {
                          orb = AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final scale = 1.0 + 0.06 * _pulseController.value;
                              return Transform.scale(
                                scale: scale,
                                child: orb,
                              );
                            },
                          );
                        }
                        return orb;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: AnimatedBuilder(
                  animation: service,
                  builder: (context, _) {
                    final nodeName =
                        service.currentNode?.name ?? '选择地区';
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _openNodes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.public,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                nodeName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: service,
                builder: (context, _) {
                  String statusText;
                  if (service.isConnecting) {
                    statusText = '正在连接...';
                  } else if (service.isConnected) {
                    statusText = '已连接';
                  } else {
                    statusText = '未连接';
                  }
                  String subtitleText;
                  if (service.isConnecting) {
                    subtitleText = '正在尝试连接，请勿断开';
                  } else if (service.isConnected) {
                    final name = service.currentNode?.name ?? '未知地区';
                    subtitleText = '已连接 · $name';
                    if (service.lastSpeedMbps > 0) {
                      subtitleText =
                          '$subtitleText · 速度 ${service.lastSpeedMbps.toStringAsFixed(1)} Mbps';
                    }
                  } else {
                    subtitleText = '点一下开始连接';
                  }
                  return Column(
                    children: [
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitleText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: service,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed:
                              (service.isConnected || service.isConnecting)
                                  ? service.disconnect
                                  : null,
                          child: const Text(
                            '断开',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A365D),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: '返回',
                          child: GestureDetector(
                            onTap: (service.isConnected || service.isConnecting)
                                ? service.disconnect
                                : null,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: '重新连接',
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueGrey,
                            ),
                            onPressed: service.isConnecting
                                ? null
                                : _reconnect,
                          ),
                        ),
                        Tooltip(
                          message: '测速设置',
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      SpeedScreen(service: service),
                                ),
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
