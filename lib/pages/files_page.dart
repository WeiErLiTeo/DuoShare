import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '文件',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 16),

          // Category Grid
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.image,
                  title: '照片',
                  subtitle: '0 个项目',
                  color: const Color(0xFFD32F2F),
                  height: 140,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.description,
                  title: '文档',
                  subtitle: '0 个项目',
                  color: const Color(0xFFa12424),
                  height: 140,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.folder_zip,
                  title: '压缩包',
                  subtitle: '0 个项目',
                  color: Colors.black54,
                  height: 100,
                  isMinimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.download,
                  title: '已接收',
                  subtitle: '0 个项目',
                  color: const Color(0xFFD32F2F),
                  height: 100,
                  isMinimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近传输',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Manrope')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connection.connectedPeers.isNotEmpty ? '${connection.connectedPeers.length} 台设备在线' : '未连接',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 空状态
          _buildEmptyState(connection),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: connection.connectedPeers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // TODO: 文件选择与发送逻辑
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('文件传输功能即将上线'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: const Color(0xFFD32F2F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ConnectionService connection) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 56, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            '暂无传输记录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87, fontFamily: 'Manrope'),
          ),
          const SizedBox(height: 8),
          Text(
            connection.connectedPeers.isEmpty
                ? '连接设备后即可开始文件传输'
                : '点击右下角按钮选择文件发送',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double height,
    bool isMinimal = false,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMinimal ? const Color(0xFFF2F4F5) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: isMinimal ? 24 : 32, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Manrope')),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}
