import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_helper.dart';
import 'database_service.dart';
import 'notification_service.dart';
import '../models/duo_message.dart';

/// 对等连接信息
class PeerConnection {
  final String name;
  final WebSocketChannel channel;
  final StreamSubscription subscription;
  bool isAlive;
  DateTime lastPong;

  PeerConnection({
    required this.name,
    required this.channel,
    required this.subscription,
    this.isAlive = true,
  }) : lastPong = DateTime.now();
}

/// WebSocket 连接管理器
/// 
/// 每台设备同时充当服务端（接受连接）和客户端（发起连接）。
/// HTTP 服务端同时提供 WebSocket 升级和文件下载功能。
class ConnectionService extends ChangeNotifier {
  HttpServer? _server;
  int _serverPort = 0;
  int get serverPort => _serverPort;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// 所有活跃的对等连接 (key = 设备名)
  final Map<String, PeerConnection> _peers = {};
  List<String> get connectedPeers => _peers.keys.toList();

  /// 收到消息的广播流
  final StreamController<DuoMessage> _messageController =
      StreamController<DuoMessage>.broadcast();
  Stream<DuoMessage> get messageStream => _messageController.stream;

  /// 本机消息历史记录（内存缓存）
  final List<DuoMessage> _messageHistory = [];
  List<DuoMessage> get messageHistory => List.unmodifiable(_messageHistory);

  /// 文件传输记录
  final List<FileRecord> _fileRecords = [];
  List<FileRecord> get fileRecords => List.unmodifiable(_fileRecords);

  /// 当前正在共享的文件 (路径 -> 文件ID)
  final Map<String, String> _sharedFiles = {};

  /// 心跳定时器
  Timer? _heartbeatTimer;
  static const _heartbeatInterval = Duration(seconds: 15);
  static const _heartbeatTimeout = Duration(seconds: 45);

  /// 断线重连缓存 (name -> {host, port})
  final Map<String, Map<String, dynamic>> _peerAddressCache = {};

  /// 文件传输进度流
  final StreamController<TransferProgress> _transferProgressController =
      StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get transferProgressStream => _transferProgressController.stream;
  final Map<String, TransferProgress> _activeTransfers = {};
  Map<String, TransferProgress> get activeTransfers => Map.unmodifiable(_activeTransfers);

  String _localName = 'Unknown';
  String get localName => _localName;
  bool _dbLoaded = false;

  /// 设置本机名称（由 DiscoveryService 提供）
  void setLocalName(String name) {
    _localName = name;
  }

  /// 从数据库加载历史记录
  Future<void> loadHistory() async {
    if (_dbLoaded) return;
    try {
      final messages = await DatabaseService.getMessages(limit: 500);
      _messageHistory.addAll(messages);
      final files = await DatabaseService.getFileRecords(limit: 200);
      _fileRecords.addAll(files);
      _dbLoaded = true;
      notifyListeners();
      if (kDebugMode) print('[ConnectionService] Loaded ${messages.length} messages, ${files.length} file records from DB');
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] DB load error: $e');
    }
  }

  /// 从历史和数据库中删除单条文件记录
  Future<void> removeFileRecord(FileRecord record) async {
    _fileRecords.remove(record);
    await DatabaseService.deleteFileRecord(record);
    notifyListeners();
  }

  // ==================== 服务端 ====================

  /// 启动 HTTP 服务端（同时处理 WebSocket 升级和文件下载）
  Future<int> startServer({int port = 0}) async {
    if (_isRunning) return _serverPort;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _serverPort = _server!.port;
      _isRunning = true;
      notifyListeners();

      if (kDebugMode) print('[ConnectionService] Server started on port $_serverPort');

      _server!.listen(_handleHttpRequest);
      _startHeartbeat();

      return _serverPort;
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] Failed to start server: $e');
      _isRunning = false;
      notifyListeners();
      return 0;
    }
  }

  /// 路由 HTTP 请求：WebSocket 升级 或 文件下载
  void _handleHttpRequest(HttpRequest request) {
    final path = request.uri.path;

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      // WebSocket 升级请求
      WebSocketTransformer.upgrade(request).then(_handleIncomingConnection);
    } else if (path.startsWith('/file/')) {
      // 文件下载请求
      _handleFileDownload(request);
    } else {
      // 其他请求返回 404
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }

  /// 处理文件下载请求
  void _handleFileDownload(HttpRequest request) async {
    final fileId = request.uri.path.replaceFirst('/file/', '');
    
    // 在共享文件中查找对应的本地路径
    String? filePath;
    for (final entry in _sharedFiles.entries) {
      if (entry.value == fileId) {
        filePath = entry.key;
        break;
      }
    }

    if (filePath == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('File not found')
        ..close();
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('File not found')
        ..close();
      return;
    }

    try {
      final fileSize = await file.length();
      final fileName = filePath.split(Platform.pathSeparator).last;
      
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set('Content-Type', 'application/octet-stream')
        ..headers.set('Content-Disposition', 'attachment; filename="$fileName"')
        ..headers.set('Content-Length', '$fileSize');
      
      // 发送端进度追踪（手动分块替代 pipe）
      final transferId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
      final tp = TransferProgress(
        id: transferId,
        fileName: fileName,
        totalBytes: fileSize,
        status: TransferStatus.transferring,
      );
      _activeTransfers[transferId] = tp;
      _transferProgressController.add(tp);
      notifyListeners();

      DateTime lastUpdate = DateTime.now();
      await for (final chunk in file.openRead()) {
        request.response.add(chunk);
        tp.receivedBytes += chunk.length;
        
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds > 300) {
          lastUpdate = now;
          _transferProgressController.add(tp);
          notifyListeners();
        }
      }
      await request.response.close();

      tp.status = TransferStatus.completed;
      _transferProgressController.add(tp);
      _activeTransfers.remove(transferId);
      notifyListeners();
      
      if (kDebugMode) print('[ConnectionService] File served: $fileName ($fileSize bytes)');
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] File serve error: $e');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Error')
          ..close();
      } catch (_) {}
    }
  }

  /// 处理一个接入的 WebSocket 连接
  void _handleIncomingConnection(WebSocket ws) {
    if (kDebugMode) print('[ConnectionService] Incoming WebSocket connection');

    final channel = IOWebSocketChannel(ws);
    String peerName = 'Peer_${_peers.length}';

    late StreamSubscription sub;
    sub = channel.stream.listen(
      (data) {
        try {
          final message = DuoMessage.fromJson(data as String);
          // 第一条消息中提取对方的名字
          if (peerName.startsWith('Peer_')) {
            peerName = message.senderName;
            if (_peers.containsKey(peerName)) {
              if (kDebugMode) print('[ConnectionService] Duplicate peer $peerName, ignoring');
              channel.sink.close();
              sub.cancel();
              return;
            }
            _peers[peerName] = PeerConnection(
              name: peerName,
              channel: channel,
              subscription: sub,
            );
            notifyListeners();
            if (kDebugMode) print('[ConnectionService] Peer identified: $peerName');
          }

          // 处理心跳
          if (message.type == MessageType.ping) {
            _sendTo(peerName, DuoMessage(
              type: MessageType.pong,
              senderName: _localName,
              payload: '',
            ));
            return;
          }

          // 处理文件通知 → 通过 HTTP 下载
          if (message.type == MessageType.fileOffer) {
            _handleFileOffer(message);
            return;
          }

          _messageHistory.add(message);
          _messageController.add(message);
          DatabaseService.insertMessage(message, isMine: false);

          // 服务端侧也触发系统通知
          if (message.type == MessageType.text) {
            NotificationService.showMessage(senderName: message.senderName, content: message.payload);
          } else if (message.type == MessageType.clipboard) {
            NotificationService.showClipboard(senderName: message.senderName, content: message.payload);
          }

          notifyListeners();
        } catch (e) {
          if (kDebugMode) print('[ConnectionService] Parse error: $e');
        }
      },
      onDone: () => _removePeer(peerName),
      onError: (error) {
        if (kDebugMode) print('[ConnectionService] Peer $peerName error: $error');
        _removePeer(peerName);
      },
    );
  }

  // ==================== 客户端 ====================

  /// 主动连接到其他设备的 WebSocket 服务端
  Future<bool> connectToPeer(String name, String host, int port) async {
    if (_peers.containsKey(name)) {
      if (kDebugMode) print('[ConnectionService] Already connected to $name');
      return true;
    }

    try {
      final uri = Uri.parse('ws://$host:$port');
      final channel = IOWebSocketChannel.connect(uri);
      await channel.ready;

      // 缓存地址供断线重连使用
      cachePeerAddress(name, host, port);

      late StreamSubscription sub;
      sub = channel.stream.listen(
        (data) {
          try {
            final message = DuoMessage.fromJson(data as String);

            if (message.type == MessageType.pong) {
              _peers[name]?.isAlive = true;
              _peers[name]?.lastPong = DateTime.now();
              return;
            }

            // 处理文件通知 → 通过 HTTP 下载
            if (message.type == MessageType.fileOffer) {
              _handleFileOffer(message);
              return;
            }

            _messageHistory.add(message);
            _messageController.add(message);
            DatabaseService.insertMessage(message, isMine: false);
            // 触发系统通知
            if (message.type == MessageType.text) {
              NotificationService.showMessage(senderName: message.senderName, content: message.payload);
            } else if (message.type == MessageType.clipboard) {
              NotificationService.showClipboard(senderName: message.senderName, content: message.payload);
            }
            notifyListeners();
          } catch (e) {
            if (kDebugMode) print('[ConnectionService] Parse error from $name: $e');
          }
        },
        onDone: () => _removePeer(name),
        onError: (error) {
          if (kDebugMode) print('[ConnectionService] Connection error with $name: $error');
          _removePeer(name);
        },
      );

      _peers[name] = PeerConnection(
        name: name,
        channel: channel,
        subscription: sub,
      );

      _sendTo(name, DuoMessage(
        type: MessageType.ping,
        senderName: _localName,
        payload: '',
      ));

      notifyListeners();
      if (kDebugMode) print('[ConnectionService] Connected to $name at $host:$port');
      return true;
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] Failed to connect to $name: $e');
      return false;
    }
  }

  // ==================== 消息收发 ====================

  void _sendTo(String peerName, DuoMessage message) {
    final peer = _peers[peerName];
    if (peer != null) {
      try {
        peer.channel.sink.add(message.toJson());
      } catch (e) {
        if (kDebugMode) print('[ConnectionService] Send error to $peerName: $e');
      }
    }
  }

  void broadcast(DuoMessage message) {
    _messageHistory.add(message);
    _messageController.add(message);
    // 持久化到数据库
    DatabaseService.insertMessage(message, isMine: message.senderName == _localName);
    for (final peer in _peers.values) {
      try {
        peer.channel.sink.add(message.toJson());
      } catch (e) {
        if (kDebugMode) print('[ConnectionService] Broadcast error to ${peer.name}: $e');
      }
    }
    notifyListeners();
  }

  void sendTextMessage(String text) {
    broadcast(DuoMessage(
      type: MessageType.text,
      senderName: _localName,
      payload: text,
    ));
  }

  void sendClipboard(String content) {
    broadcast(DuoMessage(
      type: MessageType.clipboard,
      senderName: _localName,
      payload: content,
    ));
  }

  // ==================== 文件传输 (HTTP 直传，无大小限制) ====================

  /// 发送文件：将文件注册到 HTTP 服务端，然后通过 WebSocket 通知所有对等方下载
  /// 返回: null = 成功, 字符串 = 错误信息
  Future<String?> sendFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return '文件不存在';
    }

    if (_peers.isEmpty) {
      return '没有已连接的设备';
    }

    if (!_isRunning) {
      return 'HTTP 服务未启动';
    }

    try {
      final fileSize = await file.length();
      final fileName = filePath.split(Platform.pathSeparator).last;

      // 生成唯一文件ID，注册到 HTTP 共享列表
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode.abs()}';
      _sharedFiles[filePath] = fileId;

      // 获取本机 IP 地址用于拼接下载链接
      final localIp = await _getLocalIp();
      final downloadUrl = 'http://$localIp:$_serverPort/file/$fileId';

      // 通过 WebSocket 通知对方来下载
      final message = DuoMessage(
        type: MessageType.fileOffer,
        senderName: _localName,
        payload: downloadUrl,
        metadata: {
          'fileName': fileName,
          'fileSize': fileSize,
        },
      );

      // 记录发送
      final record = FileRecord(
        fileName: fileName,
        fileSize: fileSize,
        senderName: _localName,
        timestamp: DateTime.now(),
        localPath: filePath,
      );
      _fileRecords.insert(0, record);
      DatabaseService.insertFileRecord(record, isMine: true);

      broadcast(message);

      if (kDebugMode) print('[ConnectionService] File shared: $fileName ($fileSize bytes) at $downloadUrl');
      return null;
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] File share error: $e');
      return '分享失败: $e';
    }
  }

  /// 处理收到的文件通知：通过 HTTP 下载文件到本地
  Future<void> _handleFileOffer(DuoMessage message) async {
    try {
      final downloadUrl = message.payload;
      final fileName = message.metadata?['fileName'] as String? ?? 'unknown_file';
      final fileSize = message.metadata?['fileSize'] as int? ?? 0;

      if (kDebugMode) print('[ConnectionService] Downloading file: $fileName from $downloadUrl');

      // 保存到平台对应的下载目录 (Android: Download/DuoShare, Windows: Downloads/DuoShare)
      final saveDir = await StorageHelper.getSavePath();
      final savePath = '$saveDir${Platform.pathSeparator}$fileName';
      final saveFile = File(savePath);

      // 通过 HTTP GET 流式下载（不占内存）
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        // 进度追踪下载（替代 pipe，支持进度回调）
        final transferId = '${DateTime.now().millisecondsSinceEpoch}';
        final notifyId = transferId.hashCode; // 用于通知ID
        
        final tp = TransferProgress(
          id: transferId,
          fileName: fileName,
          totalBytes: fileSize,
          status: TransferStatus.transferring,
        );
        _activeTransfers[transferId] = tp;
        _transferProgressController.add(tp);
        notifyListeners();

        NotificationService.showTransferProgress(
          id: notifyId, fileName: fileName, progress: 0, total: fileSize);

        final sink = saveFile.openWrite();
        DateTime lastUpdate = DateTime.now();
        
        await for (final chunk in response) {
          sink.add(chunk);
          tp.receivedBytes += chunk.length;
          _transferProgressController.add(tp);
          
          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds > 500) {
            lastUpdate = now;
            NotificationService.showTransferProgress(
              id: notifyId, fileName: fileName, progress: tp.receivedBytes, total: fileSize);
          }
        }
        await sink.close();

        tp.status = TransferStatus.completed;
        _transferProgressController.add(tp);
        _activeTransfers.remove(transferId);
        NotificationService.cancelNotification(notifyId);

        // 记录接收
        final record = FileRecord(
          fileName: fileName,
          fileSize: fileSize,
          senderName: message.senderName,
          timestamp: message.timestamp,
          localPath: savePath,
        );
        _fileRecords.insert(0, record);
        DatabaseService.insertFileRecord(record, isMine: false);

        _messageController.add(message);
        notifyListeners();

        // 文件接收通知
        NotificationService.showFileReceived(
          senderName: message.senderName,
          fileName: fileName,
          fileSize: record.fileSizeFormatted,
        );

        if (kDebugMode) print('[ConnectionService] File downloaded: $fileName -> $savePath');
      } else {
        if (kDebugMode) print('[ConnectionService] Download failed: HTTP ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] File download error: $e');
    }
  }

  /// 获取本机局域网 IP 地址
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] Failed to get local IP: $e');
    }
    return '127.0.0.1';
  }

  // ==================== 连接管理 ====================

  void disconnectPeer(String name) {
    final peer = _peers[name];
    if (peer != null) {
      peer.channel.sink.close();
      peer.subscription.cancel();
      _peers.remove(name);
      notifyListeners();
      if (kDebugMode) print('[ConnectionService] Disconnected from $name');
    }
  }

  void _removePeer(String name) {
    if (_peers.containsKey(name)) {
      _peers[name]?.subscription.cancel();
      _peers.remove(name);
      notifyListeners();
      if (kDebugMode) print('[ConnectionService] Peer $name disconnected');
      // 尝试自动重连
      _tryReconnect(name);
    }
  }

  bool isConnectedTo(String name) => _peers.containsKey(name);

  // ==================== 心跳检测 ====================

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      final now = DateTime.now();
      final toRemove = <String>[];

      for (final entry in _peers.entries) {
        if (!entry.value.isAlive &&
            now.difference(entry.value.lastPong) > _heartbeatTimeout) {
          toRemove.add(entry.key);
          continue;
        }
        // 发送 ping
        entry.value.isAlive = false;
        try {
          entry.value.channel.sink.add(DuoMessage(
            type: MessageType.ping,
            senderName: _localName,
            payload: '',
          ).toJson());
        } catch (_) {
          toRemove.add(entry.key);
        }
      }

      for (final name in toRemove) {
        if (kDebugMode) print('[ConnectionService] Heartbeat timeout: $name');
        _removePeer(name);
      }
    });
  }

  // ==================== 断线自动重连 ====================

  Future<void> _tryReconnect(String name) async {
    final addr = _peerAddressCache[name];
    if (addr == null) return;

    final host = addr['host'] as String;
    final port = addr['port'] as int;

    for (int i = 1; i <= 6; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (_peers.containsKey(name)) return; // 已经连上了

      if (kDebugMode) print('[ConnectionService] Reconnect attempt $i/6 to $name');
      final result = await connectToPeer(name, host, port);
      if (result) {
        if (kDebugMode) print('[ConnectionService] Reconnected to $name');
        return;
      }
    }
    if (kDebugMode) print('[ConnectionService] Gave up reconnecting to $name');
  }

  /// 缓存 peer 地址供重连使用
  void cachePeerAddress(String name, String host, int port) {
    _peerAddressCache[name] = {'host': host, 'port': port};
  }

  Future<void> shutdown() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    for (final peer in _peers.values) {
      peer.channel.sink.close();
      peer.subscription.cancel();
    }
    _peers.clear();
    _sharedFiles.clear();

    await _server?.close(force: true);
    _server = null;
    _serverPort = 0;
    _isRunning = false;
    notifyListeners();
    if (kDebugMode) print('[ConnectionService] Shutdown complete');
  }

  @override
  void dispose() {
    shutdown();
    _messageController.close();
    _transferProgressController.close();
    super.dispose();
  }
}
