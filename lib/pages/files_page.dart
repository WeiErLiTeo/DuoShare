import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:open_file/open_file.dart' as open_file;
import '../services/connection_service.dart';
import '../models/duo_message.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool _isDragging = false;
  StreamSubscription<TransferProgress>? _progressSub;
  final Map<String, TransferProgress> _transfers = {};
  
  /// 文件过滤状态：All, Sent, Received, Images, Docs, Archives
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cs = context.read<ConnectionService>();
      _progressSub = cs.transferProgressStream.listen((tp) {
        setState(() {
          if (tp.status == TransferStatus.completed || tp.status == TransferStatus.failed) {
            _transfers.remove(tp.id);
          } else {
            _transfers[tp.id] = tp;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    final fileRecords = connection.fileRecords;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    Widget body = _buildBody(connection, fileRecords);

    // Windows/桌面端：包裹拖拽区域
    if (isDesktop) {
      body = DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          for (final xFile in details.files) {
            connection.sendFile(xFile.path);
          }
          if (details.files.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已发送 ${details.files.length} 个文件'), backgroundColor: Colors.green),
            );
          }
        },
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          body,
          // 拖拽覆盖层
          if (_isDragging)
            Container(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD32F2F), width: 3, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_upload, size: 64, color: Color(0xFFD32F2F)),
                      SizedBox(height: 16),
                      Text('松手发送文件', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                    ],
                  ),
                ),
              ),
            ),
          // 传输进度覆盖层
          if (_transfers.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Column(
                children: _transfers.values.map((tp) => _buildProgressCard(tp)).toList(),
              ),
            ),
        ],
      ),
      floatingActionButton: connection.connectedPeers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _pickAndSendFile(context, connection),
              backgroundColor: const Color(0xFFD32F2F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(ConnectionService connection, List<FileRecord> fileRecords) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('文件',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Manrope')),
        const SizedBox(height: 16),

        // 统计卡片 (点击可过滤)
        Row(
          children: [
            Expanded(child: _buildCategoryCard(
              icon: Icons.upload_file, title: '已发送',
              subtitle: '${fileRecords.where((f) => f.senderName == connection.localName).length} 个文件',
              color: const Color(0xFFD32F2F), height: 120,
              isSelected: _currentFilter == 'Sent',
              onTap: () => setState(() => _currentFilter = _currentFilter == 'Sent' ? 'All' : 'Sent'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(
              icon: Icons.download, title: '已接收',
              subtitle: '${fileRecords.where((f) => f.senderName != connection.localName).length} 个文件',
              color: const Color(0xFFa12424), height: 120,
              isSelected: _currentFilter == 'Received',
              onTap: () => setState(() => _currentFilter = _currentFilter == 'Received' ? 'All' : 'Received'),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCategoryCard(icon: Icons.image, title: '图片',
              subtitle: '${_countByType(fileRecords, _imageExts)} 个', color: Colors.blue, height: 80, isMinimal: true,
              isSelected: _currentFilter == 'Images',
              onTap: () => setState(() => _currentFilter = _currentFilter == 'Images' ? 'All' : 'Images'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(icon: Icons.description, title: '文档',
              subtitle: '${_countByType(fileRecords, _docExts)} 个', color: Colors.orange, height: 80, isMinimal: true,
              isSelected: _currentFilter == 'Docs',
              onTap: () => setState(() => _currentFilter = _currentFilter == 'Docs' ? 'All' : 'Docs'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(icon: Icons.folder_zip, title: '压缩包',
              subtitle: '${_countByType(fileRecords, _archiveExts)} 个', color: Colors.black54, height: 80, isMinimal: true,
              isSelected: _currentFilter == 'Archives',
              onTap: () => setState(() => _currentFilter = _currentFilter == 'Archives' ? 'All' : 'Archives'),
            )),
          ],
        ),
        const SizedBox(height: 24),

        // 提示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF2F4F5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black38, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                Platform.isWindows ? '局域网 HTTP 直传 · 支持拖拽文件到窗口' : '局域网 HTTP 直传，无文件大小限制',
                style: const TextStyle(fontSize: 11, color: Colors.black54))),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 传输记录
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_currentFilter == 'All' ? '传输记录' : '过滤结果', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Manrope')),
            Row(
              children: [
                if (_currentFilter != 'All')
                  InkWell(
                    onTap: () => setState(() => _currentFilter = 'All'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFD32F2F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('清除过滤', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE6E8E9), borderRadius: BorderRadius.circular(8)),
                  child: Text('${fileRecords.length} 条总计', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        Builder(
          builder: (context) {
            var filtered = fileRecords;
            if (_currentFilter == 'Sent') {
              filtered = filtered.where((f) => f.senderName == connection.localName).toList();
            } else if (_currentFilter == 'Received') {
              filtered = filtered.where((f) => f.senderName != connection.localName).toList();
            } else if (_currentFilter == 'Images') {
              filtered = filtered.where((f) => _imageExts.contains(f.fileName.split('.').last.toLowerCase())).toList();
            } else if (_currentFilter == 'Docs') {
              filtered = filtered.where((f) => _docExts.contains(f.fileName.split('.').last.toLowerCase())).toList();
            } else if (_currentFilter == 'Archives') {
              filtered = filtered.where((f) => _archiveExts.contains(f.fileName.split('.').last.toLowerCase())).toList();
            }

            if (filtered.isEmpty) {
              return _buildEmptyState(connection);
            }

            return Column(
              children: filtered.map((record) => _buildFileItem(
                context: context,
                connection: connection,
                record: record,
                isMe: record.senderName == connection.localName,
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildProgressCard(TransferProgress tp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.downloading, color: Color(0xFFD32F2F), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(tp.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                Text(tp.progressPercent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD32F2F))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: tp.progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendFile(BuildContext context, ConnectionService connection) async {
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final error = await connection.sendFile(filePath);
      if (!context.mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: const Color(0xFFD32F2F)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件已发送'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: const Color(0xFFD32F2F)));
      }
    }
  }

  void _openFilePreview(BuildContext context, FileRecord record) {
    final path = record.localPath;
    if (path == null) return;

    final ext = record.fileName.split('.').last.toLowerCase();

    // 图片预览
    if (_imageExts.contains(ext)) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(child: InteractiveViewer(child: Image.file(File(path)))),
              Positioned(
                top: 8, right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 文本预览
    if (['txt', 'md', 'json', 'log', 'xml', 'yaml', 'yml', 'csv'].contains(ext)) {
      final file = File(path);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, controller) => Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(record.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    // 其他文件：用系统默认应用打开
    open_file.OpenFile.open(path);
  }

  Widget _buildEmptyState(ConnectionService connection) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text('暂无传输记录', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              connection.connectedPeers.isEmpty ? '连接设备后，可以互传文件' : '点击右下角按钮选择文件发送',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem({required BuildContext context, required ConnectionService connection, required FileRecord record, required bool isMe}) {
    final ext = record.fileName.split('.').last.toLowerCase();
    final isImage = _imageExts.contains(ext);
    final hasPath = record.localPath != null && File(record.localPath!).existsSync();

    return Dismissible(
      key: Key('${record.timestamp.millisecondsSinceEpoch}_${record.fileName}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        connection.removeFileRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除该记录'), duration: Duration(seconds: 2))
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasPath ? () => _openFilePreview(context, record) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 缩略图或文件图标
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage && hasPath
                      ? Image.file(File(record.localPath!), cacheWidth: 150, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(_getFileIcon(ext), color: Colors.black38))
                      : Icon(_getFileIcon(ext), color: const Color(0xFFD32F2F), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(isMe ? Icons.upload : Icons.download, size: 12, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text('${isMe ? "发送" : "来自 ${record.senderName}"} · ${record.fileSizeFormatted}',
                              style: const TextStyle(fontSize: 11, color: Colors.black38)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(_formatTime(record.timestamp), style: const TextStyle(fontSize: 10, color: Colors.black38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': return Icons.image;
      case 'mp4': case 'avi': case 'mov': case 'mkv': return Icons.video_file;
      case 'mp3': case 'wav': case 'flac': case 'aac': return Icons.audio_file;
      case 'pdf': return Icons.picture_as_pdf;
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz': return Icons.folder_zip;
      case 'doc': case 'docx': return Icons.article;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'apk': return Icons.android;
      case 'txt': case 'md': case 'json': case 'log': return Icons.text_snippet;
      default: return Icons.insert_drive_file;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}/${time.day}';
  }

  static const _imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
  static const _docExts = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'md'];
  static const _archiveExts = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'];

  int _countByType(List<FileRecord> records, List<String> exts) {
    return records.where((r) {
      final ext = r.fileName.split('.').last.toLowerCase();
      return exts.contains(ext);
    }).length;
  }

  Widget _buildCategoryCard({
    required IconData icon, required String title, required String subtitle,
    required Color color, required double height, bool isMinimal = false,
    bool isSelected = false, VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.all(isMinimal ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1), 
          borderRadius: BorderRadius.circular(isMinimal ? 12 : 16),
          border: isSelected ? Border.all(color: color.withValues(alpha: 0.5), width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: isMinimal ? 22 : 32, color: color),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMinimal ? 13 : 16, color: Colors.black87, fontFamily: 'Manrope')),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ])
          ],
        ),
      ),
    );
  }
}
