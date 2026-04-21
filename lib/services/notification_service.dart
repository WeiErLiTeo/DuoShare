import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 系统通知服务
///
/// Android: Material You 风格通知渠道
/// Windows: 原生 Toast 通知
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _notificationId = 0;

  /// 初始化通知插件
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 平台特定初始化
    InitializationSettings initSettings;

    if (Platform.isWindows) {
      const windowsSettings = WindowsInitializationSettings(
        appName: 'DuoShare',
        appUserModelId: 'com.example.duoshare',
        guid: 'd3b4a5c6-7e8f-9a0b-1c2d-3e4f5a6b7c8d',
      );
      initSettings = const InitializationSettings(
        android: androidSettings,
        windows: windowsSettings,
      );
    } else {
      initSettings = const InitializationSettings(
        android: androidSettings,
      );
    }

    await _plugin.initialize(settings: initSettings);
    _initialized = true;

    // Android: 创建通知渠道
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'duo_messages',
        '消息通知',
        description: '收到新消息时通知',
        importance: Importance.high,
      ));

      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'duo_files',
        '文件传输',
        description: '文件传输完成时通知',
        importance: Importance.defaultImportance,
      ));
    }

    if (kDebugMode) print('[NotificationService] Initialized');
  }

  /// 显示收到消息通知
  static Future<void> showMessage({
    required String senderName,
    required String content,
  }) async {
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'duo_messages',
        '消息通知',
        channelDescription: '收到新消息时通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      windows: Platform.isWindows ? const WindowsNotificationDetails() : null,
    );

    await _plugin.show(
      id: _notificationId++,
      title: '📱 $senderName',
      body: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      notificationDetails: details,
    );
  }

  /// 显示剪贴板同步通知
  static Future<void> showClipboard({
    required String senderName,
    required String content,
  }) async {
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'duo_messages',
        '消息通知',
        channelDescription: '收到新消息时通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      windows: Platform.isWindows ? const WindowsNotificationDetails() : null,
    );

    await _plugin.show(
      id: _notificationId++,
      title: '📋 剪贴板同步',
      body: '来自 $senderName: ${content.length > 60 ? '${content.substring(0, 60)}...' : content}',
      notificationDetails: details,
    );
  }

  /// 显示文件接收完成通知
  static Future<void> showFileReceived({
    required String senderName,
    required String fileName,
    required String fileSize,
  }) async {
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'duo_files',
        '文件传输',
        channelDescription: '文件传输完成时通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      windows: Platform.isWindows ? const WindowsNotificationDetails() : null,
    );

    await _plugin.show(
      id: _notificationId++,
      title: '📁 收到文件',
      body: '$fileName ($fileSize) 来自 $senderName',
      notificationDetails: details,
    );
  }
  /// 显示文件接收进度通知 (Android 原生进度条模式)
  static Future<void> showTransferProgress({
    required int id,
    required String fileName,
    required int progress,
    required int total,
  }) async {
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'duo_files',
        '文件传输',
        channelDescription: '文件传输完成时通知',
        importance: Importance.low, // 进度条用低优先级，避免频繁震动
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        showProgress: true,
        maxProgress: 100,
        progress: total == 0 ? 0 : (progress * 100 ~/ total),
        indeterminate: total == 0,
        ongoing: true, // 保持在通知栏
        onlyAlertOnce: true, // 只在第一次发出声音/震动
      ),
      windows: Platform.isWindows ? const WindowsNotificationDetails() : null,
    );

    int percent = total == 0 ? 0 : (progress * 100 ~/ total);
    await _plugin.show(
      id: id,
      title: '正在接收: $fileName',
      body: '$percent%',
      notificationDetails: details,
    );
  }

  /// 取消指定的通知
  static Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }
}
