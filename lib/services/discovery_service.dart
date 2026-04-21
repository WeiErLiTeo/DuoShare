import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'connection_service.dart';

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

  /// 对 ConnectionService 的引用，用于获取真实端口和发起连接
  ConnectionService? _connectionService;

  DiscoveryService() {
    _initLocalName();
  }

  /// 注入 ConnectionService 引用
  void setConnectionService(ConnectionService cs) {
    _connectionService = cs;
    cs.setLocalName(_localDeviceName);
  }

  Future<void> _initLocalName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _localDeviceName = info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _localDeviceName = info.name;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _localDeviceName = info.computerName;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _localDeviceName = info.computerName;
      } else {
        _localDeviceName = Platform.localHostname;
      }
    } catch (e) {
      _localDeviceName = Platform.localHostname.isNotEmpty ? Platform.localHostname : 'Device_${Random().nextInt(1000)}';
    }
    
    notifyListeners();
    if (_connectionService != null) {
      _connectionService!.setLocalName(_localDeviceName);
    }
  }

  /// 开始雷达扫描发现设备
  Future<void> beginScanning() async {
    if (_isDiscovering) return;
    
    // 确保 ConnectionService 的 WebSocket 服务端已启动
    if (_connectionService != null && !_connectionService!.isRunning) {
      final port = await _connectionService!.startServer();
      if (port == 0) {
        if (kDebugMode) print('[DiscoveryService] Failed to start WebSocket server');
        return;
      }
    }

    // 用真实的 WebSocket 服务端口注册 mDNS
    if (_registration == null && _connectionService != null) {
      await registerMyDevice(_connectionService!.serverPort);
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

  /// 主动连接到发现的设备
  Future<bool> connectToDevice(Service service) async {
    if (_connectionService == null) return false;
    final host = service.host;
    final port = service.port;
    final name = service.name ?? 'Unknown';
    if (host == null || port == null) return false;

    // Windows 不支持 .local mDNS 域名解析，需要手动转换为 IP 地址
    String resolvedHost = host;
    if (host.endsWith('.local') || host.endsWith('.local.')) {
      try {
        final addresses = await InternetAddress.lookup(host);
        if (addresses.isNotEmpty) {
          resolvedHost = addresses.first.address;
          if (kDebugMode) print('[DiscoveryService] Resolved $host -> $resolvedHost');
        }
      } catch (e) {
        if (kDebugMode) print('[DiscoveryService] Failed to resolve $host: $e');
        // 尝试直接用 nsd 提供的 addresses 字段
        final addrs = service.addresses;
        if (addrs != null && addrs.isNotEmpty) {
          resolvedHost = addrs.first.address;
          if (kDebugMode) print('[DiscoveryService] Using nsd address: $resolvedHost');
        } else {
          return false;
        }
      }
    }

    return await _connectionService!.connectToPeer(name, resolvedHost, port);
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
