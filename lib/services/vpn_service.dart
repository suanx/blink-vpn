import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/node.dart';

class VpnService extends ChangeNotifier {
  bool isConnected = false;
  bool isConnecting = false;
  Node? currentNode;
  double lastSpeedMbps = 0;

  final List<Node> nodes = const [
    Node(id: 'hk', name: '香港', country: '香港', city: '香港', flag: '🇭🇰', pingMs: 32, speedMbps: 120, protocol: 'VLESS'),
    Node(id: 'jp', name: '日本', country: '日本', city: '东京', flag: '🇯🇵', pingMs: 78, speedMbps: 85, protocol: 'VLESS'),
    Node(id: 'sg', name: '新加坡', country: '新加坡', city: '新加坡', flag: '🇸🇬', pingMs: 55, speedMbps: 98, protocol: 'VLESS'),
    Node(id: 'us', name: '美国', country: '美国', city: '洛杉矶', flag: '🇺🇸', pingMs: 180, speedMbps: 45, protocol: 'VLESS'),
  ];

  void selectNode(Node node) {
    currentNode = node;
    notifyListeners();
  }

  // TODO: placeholder simulated connection, real sing-box/VLESS integration goes here
  Future<void> connect() async {
    if (isConnecting || currentNode == null) return;
    isConnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    isConnected = true;
    isConnecting = false;
    notifyListeners();
  }

  void disconnect() {
    isConnected = false;
    notifyListeners();
  }

  Future<double> speedTest() async {
    try {
      final sw = Stopwatch()..start();
      final r = await http.get(Uri.parse('https://speed.cloudflare.com/__down?bytes=1000000'));
      sw.stop();
      if (r.statusCode != 200) return -1;
      final mbps = r.bodyBytes.length * 8 / sw.elapsedMilliseconds / 1000;
      lastSpeedMbps = mbps;
      notifyListeners();
      return mbps;
    } catch (_) {
      return -1;
    }
  }
}
