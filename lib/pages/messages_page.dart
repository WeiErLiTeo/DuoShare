import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '消息',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Search Indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('正在搜索本地网络设备...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Message List
          _buildMessageItem(
            icon: Icons.laptop_mac,
            name: 'MacBook Pro (办公桌)',
            time: '10:45 AM',
            message: '文件 "项目提案_草案.pdf" 已成功接收。',
            unreadCount: 2,
            isActive: true,
            isOnline: true,
          ),
          _buildMessageItem(
            icon: Icons.smartphone,
            name: 'iPhone 15 Pro',
            time: '昨天',
            message: '你需要我把照片发给你吗？',
          ),
          _buildMessageItem(
            icon: Icons.dns,
            name: '家庭媒体服务器',
            time: '星期二',
            message: '图片 已发送',
            isPhoto: true,
          ),
          _buildMessageItem(
            icon: Icons.tablet_android,
            name: 'iPad Air',
            time: '10月24日',
            message: '链接：https://github.com/...',
            opacity: 0.6,
          ),

          const SizedBox(height: 48),

          // Empty State Mock
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.none), // Custom dashed borders usually require a package, using subtle solid here
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.wifi_tethering, size: 48, color: Colors.black26),
                SizedBox(height: 16),
                Text('发现新设备', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87, fontFamily: 'Manrope')),
                SizedBox(height: 8),
                Text(
                  '连接到同一 Wi-Fi 网络即可开始即时本地聊天和文件分享。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildMessageItem({
    required IconData icon,
    required String name,
    required String time,
    required String message,
    int unreadCount = 0,
    bool isActive = false,
    bool isOnline = false,
    bool isPhoto = false,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFD32F2F).withValues(alpha: 0.1) : const Color(0xFFF2F4F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isActive ? const Color(0xFFD32F2F) : Colors.black38, size: 28),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87, fontFamily: 'Manrope'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFFD32F2F) : Colors.black38)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isPhoto) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.image, size: 14, color: Colors.black54)),
                            Expanded(child: Text(message, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                          child: Center(child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
