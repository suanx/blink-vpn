import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class NodesScreen extends StatelessWidget {
  final VpnService service;
  const NodesScreen({super.key, required this.service});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Node')),
      body: AnimatedBuilder(
        animation: service,
        builder: (_, __) => ListView.builder(
          itemCount: service.nodes.length,
          itemBuilder: (_, i) {
            final n = service.nodes[i];
            return ListTile(
              leading: Text(n.flag, style: const TextStyle(fontSize: 20)),
              title: Text(n.name, style: const TextStyle(fontSize: 14)),
              subtitle: Text('${n.city} - ${n.pingMs}ms - ${n.speedMbps} Mbps',
                  style: const TextStyle(fontSize: 12)),
              trailing: n == service.currentNode ? const Icon(Icons.check) : null,
              onTap: () => service.selectNode(n),
            );
          },
        ),
      ),
    );
  }
}
