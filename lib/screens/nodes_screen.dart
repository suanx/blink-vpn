import 'package:flutter/material.dart';
import '../models/node.dart';
import '../services/vpn_service.dart';

class NodesScreen extends StatelessWidget {
  final VpnService service;

  const NodesScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择节点'),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, child) {
          return ListView.builder(
            itemCount: service.nodes.length,
            itemBuilder: (context, index) {
              final n = service.nodes[index];
              return ListTile(
                leading: Text(n.flag, style: const TextStyle(fontSize: 20)),
                title: Text(n.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${n.city} · ${n.pingMs}毫秒 · ${n.speedMbps} Mbps',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: n == service.currentNode
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () {
                  service.selectNode(n);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}