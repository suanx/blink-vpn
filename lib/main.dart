import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/vpn_service.dart';
import 'screens/home_screen.dart';
import 'screens/nodes_screen.dart';
import 'screens/speed_screen.dart';

void main() => runApp(const BlinkApp());

class BlinkApp extends StatelessWidget {
  const BlinkApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink VPN',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const BlinkHome(),
    );
  }
}

class BlinkHome extends StatefulWidget {
  const BlinkHome({super.key});
  @override
  State<BlinkHome> createState() => _BlinkHomeState();
}

class _BlinkHomeState extends State<BlinkHome> {
  final service = VpnService();
  int index = 0;

  @override
  void initState() {
    super.initState();
    service.currentNode = service.nodes.first;
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  List<Widget> get pages => [
        HomeScreen(service: service),
        NodesScreen(service: service),
        SpeedScreen(service: service),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (v) => setState(() => index = v),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.public), label: 'Nodes'),
          BottomNavigationBarItem(icon: const Icon(Icons.speed), label: 'Speed'),
        ],
      ),
    );
  }
}
