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
      // 只用浅色主题：不跟随系统深色模式，顶栏和页面颜色统一为白色
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: '节点'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: '测速'),
        ],
      ),
    );
  }
}
