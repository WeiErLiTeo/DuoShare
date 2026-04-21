import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../models/duo_message.dart';

class ClipboardPage extends StatefulWidget {
  const ClipboardPage({Key? key}) : super(key: key);

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final List<DuoMessage> _clipboardHistory = [];
  StreamSubscription<DuoMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cs = context.read<ConnectionService>();
      // 从历史记录中加载已有的剪贴板消息
      _clipboardHistory.addAll(
        cs.messageHistory.where((m) => m.type == MessageType.clipboard),
      );
      // 监听新的剪贴板消息
      _subscription = cs.messageStream.listen((msg) {
        if (msg.type == MessageType.clipboard) {
          setState(() {
            _clipboardHistory.insert(0, msg);
          });
        }
      });
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),

          // 筛选 Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(),
          ),
          const SizedBox(height: 16),

          // 列表内容
          Expanded(
            child: _clipboardHistory.isEmpty
                ? _buildEmptyState(connection)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _clipboardHistory.length,
                    itemBuilder: (context, index) {
                      final msg = _clipboardHistory[index];
                      return _buildClipboardCard(
                        context: context,
                        icon: Icons.devices,
                        device: msg.senderName.toUpperCase(),
                        time: _formatTime(msg.timestamp),
                        content: msg.payload,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: connection.connectedPeers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _sendCurrentClipboard(connection),
              backgroundColor: const Color(0xFFD32F2F),
              child: const Icon(Icons.content_paste_go, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ConnectionService connection) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_paste_off, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text(
              '暂无剪贴板记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              connection.connectedPeers.isEmpty
                  ? '连接设备后，可以互相推送剪贴板内容'
                  : '点击右下角按钮发送当前剪贴板内容',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCurrentClipboard(ConnectionService connection) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      connection.sendClipboard(data.text!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('剪贴板内容已推送'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('剪贴板为空'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: '搜索片段...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: Icon(Icons.search, color: Colors.black38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('全部', isSelected: true),
          const SizedBox(width: 8),
          _buildChip('链接', isSelected: false),
          const SizedBox(width: 8),
          _buildChip('代码', isSelected: false),
          const SizedBox(width: 8),
          _buildChip('文本', isSelected: false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFFE6E8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildClipboardCard({
    required BuildContext context,
    required IconData icon,
    required String device,
    required String time,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFFD32F2F)),
                    const SizedBox(width: 6),
                    Text(
                      '来自: $device',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.content_copy, size: 16, color: Color(0xFFD32F2F)),
                        SizedBox(width: 4),
                        Text('复制', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
