import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StartupService {
  /// 获取 Windows 下的 Startup 文件夹内 DuoShare 快捷方式的绝对路径
  static String get _shortcutPath {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) return '';
    return p.join(appData, 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup', 'DuoShare.lnk');
  }

  /// 检查是否已开启开机自启（只需判断快捷方式是否存在）
  static bool isEnabled() {
    if (!Platform.isWindows) return false;
    final path = _shortcutPath;
    if (path.isEmpty) return false;
    return File(path).existsSync();
  }

  /// 切换自启状态：如果开启，则在 Startup 文件夹建立快捷方式，否则删除
  static Future<void> toggleStartup(bool enable) async {
    if (!Platform.isWindows) return;

    final shortcutPath = _shortcutPath;
    if (shortcutPath.isEmpty) return;
    final targetPath = Platform.resolvedExecutable;
    final workingDir = p.dirname(targetPath);

    if (enable) {
      if (kDebugMode) print('[StartupService] Enabling startup shortcut at $shortcutPath');
      // 使用 PowerShell WScript.Shell 动态创建快捷方式，免注册表，纯粹绿色
      final script = '''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
\$Shortcut.TargetPath = "$targetPath"
\$Shortcut.WorkingDirectory = "$workingDir"
\$Shortcut.Save()
''';
      await Process.run('powershell', ['-Command', script]);
    } else {
      if (kDebugMode) print('[StartupService] Disabling startup shortcut');
      final file = File(shortcutPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
