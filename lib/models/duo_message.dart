import 'dart:convert';

/// 消息类型枚举
enum MessageType {
  text,       // 普通文本消息
  clipboard,  // 剪贴板同步
  fileOffer,  // 文件传输请求
  fileAccept, // 文件传输接受
  ping,       // 心跳检测
  pong,       // 心跳回应
}

/// DuoShare 统一消息协议
class DuoMessage {
  final MessageType type;
  final String senderName;
  final String payload;
  final DateTime timestamp;

  DuoMessage({
    required this.type,
    required this.senderName,
    required this.payload,
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
      'timestamp': timestamp.toIso8601String(),
    });
  }

  @override
  String toString() => 'DuoMessage(type: ${type.name}, sender: $senderName, payload: $payload)';
}
