import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/duo_message.dart';

/// 文件传输大小限制 (10 MB)
const int _maxFileSize = 10 * 1024 * 1024;

/// 对等连接信息
class PeerConnection {
  final String name;
  final WebSocketChannel channel;
  final StreamSubscription subscription;
  bool isAlive;

  PeerConnection({
    required this.name,
    required this.channel,
    required this.subscription,
    this.isAlive = true,
  });
}

/// WebSocket 连接管理器
/// 
/// 每台设备同时充当服务端（接受连接）和客户端（发起连接）。
/// 使用 dart:io 的 HttpServer 作为 WebSocket 服务端，
/// 使用 web_socket_channel 作为客户端。
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

  String _localName = 'Unknown';
  String get localName => _localName;

  /// 设置本机名称（由 DiscoveryService 提供）
  void setLocalName(String name) {
    _localName = name;
  }

  // ==================== 服务端 ====================

  /// 启动 WebSocket 服务端，监听指定端口（0 = 系统自动分配）
  Future<int> startServer({int port = 0}) async {
    if (_isRunning) return _serverPort;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _serverPort = _server!.port;
      _isRunning = true;
      notifyListeners();

      if (kDebugMode) print('[ConnectionService] Server started on port $_serverPort');

      _server!.transform(WebSocketTransformer()).listen(
        _handleIncomingConnection,
        onError: (error) {
          if (kDebugMode) print('[ConnectionService] Server error: $error');
        },
      );

      return _serverPort;
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] Failed to start server: $e');
      _isRunning = false;
      notifyListeners();
      return 0;
    }
  }

  /// 处理一个接入的 WebSocket 连接
  void _handleIncomingConnection(WebSocket ws) {
    if (kDebugMode) print('[ConnectionService] Incoming connection');

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
            // 如果已经有同名连接，不重复添加
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

          // 处理收到的文件
          if (message.type == MessageType.fileData) {
            _handleReceivedFile(message);
            return;
          }

          _messageHistory.add(message);
          _messageController.add(message);
          notifyListeners();
        } catch (e) {
          if (kDebugMode) print('[ConnectionService] Parse error: $e');
        }
      },
      onDone: () {
        _removePeer(peerName);
      },
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

      // 等待连接就绪
      await channel.ready;

      late StreamSubscription sub;
      sub = channel.stream.listen(
        (data) {
          try {
            final message = DuoMessage.fromJson(data as String);

            if (message.type == MessageType.pong) {
              _peers[name]?.isAlive = true;
              return;
            }

            // 处理收到的文件
            if (message.type == MessageType.fileData) {
              _handleReceivedFile(message);
              return;
            }

            _messageHistory.add(message);
            _messageController.add(message);
            notifyListeners();
          } catch (e) {
            if (kDebugMode) print('[ConnectionService] Parse error from $name: $e');
          }
        },
        onDone: () {
          _removePeer(name);
        },
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

      // 立刻发送一条 ping 让对方知道我们是谁
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

  /// 向指定对等方发送消息
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

  /// 向所有已连接的设备广播消息
  void broadcast(DuoMessage message) {
    // 也把自己发的消息加入历史
    _messageHistory.add(message);
    _messageController.add(message);

    for (final peer in _peers.values) {
      try {
        peer.channel.sink.add(message.toJson());
      } catch (e) {
        if (kDebugMode) print('[ConnectionService] Broadcast error to ${peer.name}: $e');
      }
    }
    notifyListeners();
  }

  /// 发送文本消息给所有对等方
  void sendTextMessage(String text) {
    broadcast(DuoMessage(
      type: MessageType.text,
      senderName: _localName,
      payload: text,
    ));
  }

  /// 发送剪贴板内容给所有对等方
  void sendClipboard(String content) {
    broadcast(DuoMessage(
      type: MessageType.clipboard,
      senderName: _localName,
      payload: content,
    ));
  }

  // ==================== 文件传输 ====================

  /// 发送文件给所有已连接的设备
  /// 读取文件内容，base64 编码后通过 WebSocket 发送
  /// 返回: null = 成功, 字符串 = 错误信息
  Future<String?> sendFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return '文件不存在';
    }

    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      return '文件过大 (最大 ${_maxFileSize ~/ (1024 * 1024)} MB)';
    }

    if (_peers.isEmpty) {
      return '没有已连接的设备';
    }

    try {
      final bytes = await file.readAsBytes();
      final base64Content = base64Encode(bytes);
      final fileName = filePath.split(Platform.pathSeparator).last;

      final message = DuoMessage(
        type: MessageType.fileData,
        senderName: _localName,
        payload: base64Content,
        metadata: {
          'fileName': fileName,
          'fileSize': fileSize,
        },
      );

      // 记录发送记录
      _fileRecords.insert(0, FileRecord(
        fileName: fileName,
        fileSize: fileSize,
        senderName: _localName,
        timestamp: DateTime.now(),
        localPath: filePath,
      ));

      broadcast(message);

      if (kDebugMode) print('[ConnectionService] File sent: $fileName ($fileSize bytes)');
      return null; // 成功
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] File send error: $e');
      return '发送失败: $e';
    }
  }

  /// 处理收到的文件数据
  Future<void> _handleReceivedFile(DuoMessage message) async {
    try {
      final fileName = message.metadata?['fileName'] as String? ?? 'unknown_file';
      final fileSize = message.metadata?['fileSize'] as int? ?? 0;
      final bytes = base64Decode(message.payload);

      // 保存到本地下载目录
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/DuoShare');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final savePath = '${saveDir.path}/$fileName';
      final file = File(savePath);
      await file.writeAsBytes(bytes);

      // 记录接收记录
      _fileRecords.insert(0, FileRecord(
        fileName: fileName,
        fileSize: fileSize,
        senderName: message.senderName,
        timestamp: message.timestamp,
        localPath: savePath,
      ));

      // 通知 UI
      _messageController.add(message);
      notifyListeners();

      if (kDebugMode) print('[ConnectionService] File received: $fileName -> $savePath');
    } catch (e) {
      if (kDebugMode) print('[ConnectionService] File receive error: $e');
    }
  }

  // ==================== 连接管理 ====================

  /// 断开与某个设备的连接
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

  /// 内部：移除断开的对等方
  void _removePeer(String name) {
    if (_peers.containsKey(name)) {
      _peers[name]?.subscription.cancel();
      _peers.remove(name);
      notifyListeners();
      if (kDebugMode) print('[ConnectionService] Peer $name disconnected');
    }
  }

  /// 检查是否已连接到某设备
  bool isConnectedTo(String name) => _peers.containsKey(name);

  /// 关闭服务，断开所有连接
  Future<void> shutdown() async {
    for (final peer in _peers.values) {
      peer.channel.sink.close();
      peer.subscription.cancel();
    }
    _peers.clear();

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
    super.dispose();
  }
}

