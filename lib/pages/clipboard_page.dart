import 'package:flutter/material.dart';

class ClipboardPage extends StatelessWidget {
  const ClipboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 24),
          const Text(
            '最近活动',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildClipboardCard(
            context: context,
            icon: Icons.laptop_windows,
            device: 'WINDOWS PC',
            time: '2分钟前',
            child: const Text('https://github.com/google/material-design-icons/releases/tag/4.0.0', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          _buildClipboardCard(
            context: context,
            icon: Icons.smartphone,
            device: 'PIXEL 8 PRO',
            time: '15分钟前',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'const observer = new IntersectionObserver((entries) => {\n  entries.forEach(entry => console.log(entry));\n});',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
          _buildClipboardCard(
            context: context,
            icon: Icons.tablet_mac,
            device: 'IPAD AIR',
            time: '1小时前',
            child: const Text('晚上7点在5街和主街交汇处集合，参加团队晚宴。别忘了带报告！'),
          ),
          _buildClipboardCard(
            context: context,
            icon: Icons.laptop_windows,
            device: 'WINDOWS PC',
            time: '3小时前',
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1498050108023-c5249f4df085?q=80&w=600&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
    );
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

  Widget _buildClipboardCard({required BuildContext context, required IconData icon, required String device, required String time, required Widget child}) {
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
            child,
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 20),
                  color: const Color(0xFFD32F2F),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {},
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
