import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class SpeedScreen extends StatefulWidget {
  final VpnService service;
  const SpeedScreen({super.key, required this.service});

  @override
  State<SpeedScreen> createState() => _SpeedScreenState();
}

class _SpeedScreenState extends State<SpeedScreen> {
  bool testing = false;
  double? result;

  Future<void> runTest() async {
    setState(() {
      testing = true;
      result = null;
    });
    final value = await widget.service.speedTest();
    setState(() {
      testing = false;
      result = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (testing)
              const CircularProgressIndicator()
            else if (result != null && result! >= 0)
              Text(
                '${result!.toStringAsFixed(1)} Mbps',
                style: const TextStyle(fontSize: 15),
              )
            else if (result != null)
              const Text(
                'Test failed, try again',
                style: TextStyle(fontSize: 13),
              )
            else
              const Text(
                'Tap Start to test your speed',
                style: TextStyle(fontSize: 13),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: testing ? null : runTest,
              child: const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }
}
