import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/discovery_service.dart';
import '../services/connection_service.dart';
import '../services/storage_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _cacheSize = 0;
  int _fileCount = 0;
  String _savePath = '加载中...';

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final path = await StorageHelper.getSavePath();
    final size = await StorageHelper.getCacheSize();
    final count = await StorageHelper.getFileCount();
    if (mounted) {
      setState(() {
        _savePath = path;
        _cacheSize = size;
        _fileCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryService>();
    final connection = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 24),

          // 设备信息
          _buildSectionHeader('设备信息'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.devices,
            title: '本机名称',
            value: discovery.localDeviceName,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.cell_tower,
            title: 'WebSocket 服务端口',
            value: connection.isRunning ? '${connection.serverPort}' : '未启动',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.link,
            title: '已连接设备',
            value: connection.connectedPeers.isEmpty
                ? '无'
                : connection.connectedPeers.join(', '),
          ),
          const SizedBox(height: 24),

          // 服务状态
          _buildSectionHeader('服务状态'),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.wifi_tethering,
            title: 'WebSocket 服务',
            subtitle: connection.isRunning ? '正在监听端口 ${connection.serverPort}' : '未运行',
            value: connection.isRunning,
            onChanged: (value) async {
              if (value) {
                await connection.startServer();
              } else {
                await connection.shutdown();
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.radar,
            title: 'mDNS 设备雷达',
            subtitle: discovery.isDiscovering ? '正在扫描局域网...' : '未开启',
            value: discovery.isDiscovering,
            onChanged: (value) {
              if (value) {
                discovery.beginScanning();
              } else {
                discovery.stopScanning();
              }
            },
          ),

          const SizedBox(height: 24),

          // 存储管理
          _buildSectionHeader('存储管理'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.folder,
            title: '文件保存位置',
            value: _savePath,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.storage,
            title: '已用空间',
            value: '$_fileCount 个文件 · ${StorageHelper.formatSize(_cacheSize)}',
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.delete_sweep,
            title: '清除已接收的文件',
            subtitle: '删除 DuoShare 目录中的所有文件',
            onTap: () => _showClearCacheDialog(context),
          ),

          const SizedBox(height: 24),

          // 连接管理
          if (connection.connectedPeers.isNotEmpty) ...[
            _buildSectionHeader('连接管理'),
            const SizedBox(height: 12),
            ...connection.connectedPeers.map((name) => _buildPeerTile(
              context: context,
              name: name,
              connection: connection,
            )),
            const SizedBox(height: 24),
          ],

          // 关于
          _buildSectionHeader('关于'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.info_outline,
            title: '版本',
            value: '1.0.0',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.code,
            title: '协议',
            value: 'WebSocket + mDNS + HTTP (局域网传输)',
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('确定要删除 DuoShare 文件夹中的所有文件吗？\n\n当前：$_fileCount 个文件，${StorageHelper.formatSize(_cacheSize)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await StorageHelper.clearCache();
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(success ? '缓存已清除' : '清除失败'),
                  backgroundColor: success ? Colors.green : const Color(0xFFD32F2F),
                ));
                _loadStorageInfo();
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('确认删除', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? Colors.green : Colors.black38, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFD32F2F),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD32F2F), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerTile({
    required BuildContext context,
    required String name,
    required ConnectionService connection,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('WebSocket 已连接', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              connection.disconnectPeer(name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已断开 $name'), duration: const Duration(seconds: 2)),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('断开', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
