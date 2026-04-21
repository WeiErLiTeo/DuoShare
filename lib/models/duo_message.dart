import 'dart:convert';

/// 消息类型枚举
enum MessageType {
  text,       // 普通文本消息
  clipboard,  // 剪贴板同步
  fileOffer,  // 文件传输请求 (payload = 文件名, metadata = {size, mimeType})
  fileData,   // 文件数据传输 (payload = base64 编码的文件内容, metadata = {fileName})
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
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
