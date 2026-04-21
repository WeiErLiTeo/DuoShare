import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/discovery_service.dart';
import '../services/connection_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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

          // 设备信息卡片
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
            value: 'WebSocket + mDNS (局域网传输)',
          ),
          const SizedBox(height: 80),
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
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
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
