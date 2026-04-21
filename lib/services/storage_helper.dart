import 'dart:io';
import 'package:flutter/foundation.dart';

/// 文件存储路径管理
/// 
/// Android: /storage/emulated/0/Download/DuoShare/
/// Windows: %USERPROFILE%\Downloads\DuoShare\
class StorageHelper {
  static String? _cachedPath;

  /// 获取 DuoShare 文件保存目录
  static Future<String> getSavePath() async {
    if (_cachedPath != null) return _cachedPath!;

    String basePath;

    if (Platform.isAndroid) {
      // Android: 公共 Download 目录
      basePath = '/storage/emulated/0/Download/DuoShare';
    } else if (Platform.isWindows) {
      // Windows: 用户 Downloads 目录 (不污染 C 盘其他位置)
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        basePath = '$userProfile\\Downloads\\DuoShare';
      } else {
        // 兜底：放在 exe 同级目录
        basePath = '${Directory.current.path}\\DuoShare';
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      basePath = '$home/Downloads/DuoShare';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      basePath = '$home/Downloads/DuoShare';
    } else {
      basePath = Directory.current.path;
    }

    // 确保目录存在
    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _cachedPath = basePath;
    if (kDebugMode) print('[StorageHelper] Save path: $basePath');
    return basePath;
  }

  /// 获取 DuoShare 目录大小 (字节)
  static Future<int> getCacheSize() async {
    final path = await getSavePath();
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// 获取 DuoShare 目录中的文件数量
  static Future<int> getFileCount() async {
    final path = await getSavePath();
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) count++;
    }
    return count;
  }

  /// 清空 DuoShare 缓存目录
  static Future<bool> clearCache() async {
    try {
      final path = await getSavePath();
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true); // 重新创建空目录
      }
      if (kDebugMode) print('[StorageHelper] Cache cleared');
      return true;
    } catch (e) {
      if (kDebugMode) print('[StorageHelper] Clear cache error: $e');
      return false;
    }
  }

  /// 格式化文件大小
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
