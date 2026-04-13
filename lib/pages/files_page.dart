import 'package:flutter/material.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 头部大标题（如果需要独立展示）
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

          // Storage Usage Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F5),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('存储空间',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '128.5 GB',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFD32F2F),
                                  fontFamily: 'Manrope'),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '/ 256 GB',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '剩余 50%',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E8E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                          width: 120,
                          decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(10))),
                      Container(
                          width: 50,
                          decoration: const BoxDecoration(
                              color: Color(0xFFff7777))), // 浅红
                      Container(
                          width: 30,
                          decoration: const BoxDecoration(
                              color: Color(0xFF8b0000))), // 深红
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFFD32F2F), '视频与照片'),
                    const SizedBox(width: 12),
                    _buildLegendItem(const Color(0xFFff7777), '文档'),
                    const SizedBox(width: 12),
                    _buildLegendItem(const Color(0xFF8b0000), '其他'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Grid
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.image,
                  title: '照片',
                  subtitle: '2,458 个项目',
                  color: const Color(0xFFD32F2F),
                  height: 140,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.description,
                  title: '文档',
                  subtitle: '412 个项目',
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
                  subtitle: '86 个项目',
                  color: Colors.black54,
                  height: 100,
                  isMinimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  icon: Icons.download,
                  title: '下载',
                  subtitle: '154 个项目',
                  color: const Color(0xFFD32F2F),
                  height: 100,
                  isMinimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cloud Sync Setup
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_done, color: Color(0xFFD32F2F)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('云端同步',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('上次同步：2分钟前',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('立即同步',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Activity List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近文件',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Manrope')),
              TextButton(
                onPressed: () {},
                child: const Text('查看全部',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentFile(
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              title: 'Q3季度财务报表.pdf',
              subtitle: '1.2 MB • 2小时前'),
          _buildRecentFile(
              icon: Icons.image,
              color: Colors.blue,
              title: 'IMG_20231024_HD.jpg',
              subtitle: '4.5 MB • 昨天',
              isImage: true),
          _buildRecentFile(
              icon: Icons.article,
              color: Colors.orange,
              title: '产品设计说明书 v2.docx',
              subtitle: '856 KB • 10月20日'),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
      ],
    );
  }

  Widget _buildCategoryCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required double height,
      bool isMinimal = false}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isMinimal ? const Color(0xFFF2F4F5) : color.withValues(alpha: 0.1),
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

  Widget _buildRecentFile(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      bool isImage = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?q=80&w=200&auto=format&fit=crop',
                        fit: BoxFit.cover),
                  )
                : Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.black38),
        ],
      ),
    );
  }
}
