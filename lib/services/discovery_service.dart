import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

class DiscoveryService extends ChangeNotifier {
  static const String _serviceType = '_duoshare._tcp';
  
  Registration? _registration;
  Discovery? _discovery;
  
  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  final List<Service> _devices = [];
  List<Service> get devices => _devices;

  String _localDeviceName = 'Unknown Device';
  String get localDeviceName => _localDeviceName;

  DiscoveryService() {
    _initLocalName();
  }

  void _initLocalName() {
    // 权宜之计：使用系统的 localHostname 作为广播名称，或生成随机ID
    try {
      _localDeviceName = Platform.localHostname;
    } catch (e) {
      _localDeviceName = 'Device_${Random().nextInt(1000)}';
    }
    notifyListeners();
  }

  /// 开始雷达扫描发现设备
  Future<void> beginScanning() async {
    if (_isDiscovering) return;
    
    // 如果还未注册自己，马上注册一个随机端口的空壳服务，好让别人能发现我们
    if (_registration == null) {
      await registerMyDevice(Random().nextInt(10000) + 40000);
    }

    try {
      _isDiscovering = true;
      _devices.clear();
      notifyListeners();

      _discovery = await startDiscovery(_serviceType, autoResolve: true);
      _discovery!.addServiceListener((service, status) {
        if (status == ServiceStatus.found) {
          // 排除掉自己扫描到自己的情况
          if (service.name != _localDeviceName) {
            if (!_devices.any((d) => d.name == service.name)) {
              _devices.add(service);
              notifyListeners();
            }
          }
        } else if (status == ServiceStatus.lost) {
           _devices.removeWhere((d) => d.name == service.name);
           notifyListeners();
        }
      });
    } catch (e) {
      if (kDebugMode) print('Discovery error: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// 停止扫描
  Future<void> stopScanning() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
    _isDiscovering = false;
    _devices.clear();
    notifyListeners();
  }

  /// 启动 HTTP 时将本机注册广播至局域网
  Future<void> registerMyDevice(int port) async {
    try {
      _registration = await register(Service(
        name: _localDeviceName,
        type: _serviceType,
        port: port,
      ));
      if (kDebugMode) print('Successfully registered $_localDeviceName on port $port');
    } catch (e) {
      if (kDebugMode) print('Registration error: $e');
    }
  }

  @override
  void dispose() {
    if (_registration != null) {
      unregister(_registration!);
    }
    if (_discovery != null) {
      stopDiscovery(_discovery!);
    }
    super.dispose();
  }
}
