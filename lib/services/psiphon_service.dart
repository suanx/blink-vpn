// Psiphon 应急模式（代理模式，第 1 阶段）。
// 只提供本机 SOCKS5 / HTTP 代理（127.0.0.1），供应用内流量使用。
// 不是全设备 VPN：第 2 阶段（VpnService + tun2socks 全设备路由）未做。
// 代码来源：Kilo nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free 起草，
// Bike 审阅后重写：修正了原稿的方向错误（把 start/stop 当成入站调用）、
// 不存在的 ProxySettings API、以及未调用 invokeMethod 的问题。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum PsiphonState { idle, connecting, connected, error }

class PsiphonService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('blink_vpn/psiphon');

  PsiphonState _state = PsiphonState.idle;
  int _socksPort = 0;
  int _httpPort = 0;
  String _lastNotice = '';
  String _lastError = '';
  String _exitIp = '';
  String _region = '';

  PsiphonState get state => _state;
  int get socksPort => _socksPort;
  int get httpPort => _httpPort;
  String get lastNotice => _lastNotice;
  String get lastError => _lastError;
  String get exitIp => _exitIp;
  String get region => _region;
  bool get isConnected => _state == PsiphonState.connected;
  bool get isConnecting => _state == PsiphonState.connecting;

  PsiphonService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPsiphonNotice':
        final args = call.arguments;
        if (args is Map) {
          _lastNotice = (args['message'] ?? args['notice'] ?? '').toString();
          if (args['socksPort'] is int) _socksPort = args['socksPort'] as int;
          if (args['httpPort'] is int) _httpPort = args['httpPort'] as int;
          if (args['region'] is String) _region = args['region'] as String;
        } else if (args is String) {
          _lastNotice = args;
        }
        notifyListeners();
        break;
      case 'onPsiphonConnected':
        final args = call.arguments;
        if (args is Map) {
          if (args['socksPort'] is int) _socksPort = args['socksPort'] as int;
          if (args['httpPort'] is int) _httpPort = args['httpPort'] as int;
          if (args['region'] is String) _region = args['region'] as String;
        }
        _state = PsiphonState.connected;
        _lastError = '';
        notifyListeners();
        break;
      case 'onPsiphonError':
        final args = call.arguments;
        _lastError = args is Map
            ? (args['message'] ?? '').toString()
            : args.toString();
        _state = PsiphonState.error;
        notifyListeners();
        break;
    }
  }

  /// 启动 Psiphon 隧道。Kotlin 侧 startTunneling() 是异步返回的，
  /// 所以这里只表示“已开始启动”，真正连通以 onPsiphonConnected 回调为准。
  Future<void> startPsiphon() async {
    if (_state == PsiphonState.connecting ||
        _state == PsiphonState.connected) {
      return;
    }
    _state = PsiphonState.connecting;
    _lastError = '';
    _lastNotice = '正在连接 Psiphon…';
    notifyListeners();
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('startPsiphon');
      if (result != null) {
        if (result['socksPort'] is int) _socksPort = result['socksPort'] as int;
        if (result['httpPort'] is int) _httpPort = result['httpPort'] as int;
      }
      // 仍保持 connecting，直到 onPsiphonConnected 到达。
      notifyListeners();
    } on PlatformException catch (e) {
      _state = PsiphonState.error;
      _lastError = e.message ?? e.code;
      notifyListeners();
    }
  }

  Future<void> stopPsiphon() async {
    try {
      await _channel.invokeMethod<void>('stopPsiphon');
    } on PlatformException catch (e) {
      _lastError = e.message ?? e.code;
    }
    _state = PsiphonState.idle;
    _socksPort = 0;
    _httpPort = 0;
    _exitIp = '';
    _region = '';
    notifyListeners();
  }

  /// 经本地 SOCKS5 代理查询出口 IP，验证流量确实走了隧道。
  /// 返回出口 IP，失败返回 ''（不抛异常）。
  Future<String> checkExitIp() async {
    if (_socksPort == 0) return '';
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.findProxy = (_) => 'SOCKS5 127.0.0.1:$_socksPort';
    try {
      final request =
          await client.getUrl(Uri.parse('https://api.ipify.org'));
      final response = await request.close().timeout(
            const Duration(seconds: 15),
          );
      final body = await response.transform(utf8.decoder).join();
      final ip = body.trim();
      if (ip.isNotEmpty && response.statusCode == 200) {
        _exitIp = ip;
        notifyListeners();
        return ip;
      }
      return '';
    } catch (_) {
      return '';
    } finally {
      client.close();
    }
  }
}
