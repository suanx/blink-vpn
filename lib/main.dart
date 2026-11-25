import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/vpn_service.dart';
import 'screens/home_screen.dart';

void main() => runApp(const BlinkApp());

class BlinkApp extends StatelessWidget {
  const BlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink VPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
  final VpnService service = VpnService();

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

  @override
  Widget build(BuildContext context) {
    return HomeScreen(service: service);
  }
}