import 'dart:convert';

/// 消息类型枚举
enum MessageType {
  text,       // 普通文本消息
  clipboard,  // 剪贴板同步
  fileOffer,  // 文件传输通知 (payload = HTTP 下载链接, metadata = {fileName, fileSize})
  ping,       // 心跳检测
  pong,       // 心跳回应
}

/// DuoShare 统一消息协议
class DuoMessage {
  final MessageType type;
  final String senderName;
  final String payload;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DuoMessage({
    required this.type,
    required this.senderName,
    required this.payload,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 从 JSON 字符串解码
  factory DuoMessage.fromJson(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return DuoMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      senderName: map['senderName'] as String? ?? 'Unknown',
      payload: map['payload'] as String? ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 编码为 JSON 字符串
  String toJson() {
    return json.encode({
      'type': type.name,
      'senderName': senderName,
      'payload': payload,
      if (metadata != null) 'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  @override
  String toString() => 'DuoMessage(type: ${type.name}, sender: $senderName, payload: ${payload.length > 50 ? '${payload.substring(0, 50)}...' : payload})';
}

/// 文件传输记录
class FileRecord {
  final String fileName;
  final int fileSize;
  final String senderName;
  final DateTime timestamp;
  final String? localPath; // 接收后的本地存储路径

  FileRecord({
    required this.fileName,
    required this.fileSize,
    required this.senderName,
    required this.timestamp,
    this.localPath,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 文件传输状态
enum TransferStatus { waiting, transferring, completed, failed }

/// 文件传输进度追踪
class TransferProgress {
  final String id;
  final String fileName;
  final int totalBytes;
  int receivedBytes;
  TransferStatus status;
  final bool isSending;

  TransferProgress({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.receivedBytes = 0,
    this.status = TransferStatus.waiting,
    this.isSending = false,
  });

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';
}
