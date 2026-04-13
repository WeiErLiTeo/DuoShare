import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/discovery_service.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 纯白主体背景
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          // 1. Mesh Status Hero
          _buildMeshStatusHero(context, discovery),
          const SizedBox(height: 12),

          // 2. Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatCard(context, Icons.speed, '传输速度', discovery.isDiscovering ? '监测中' : '待命')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, Icons.timer, '延迟', discovery.isDiscovering ? '< 5ms' : '-')),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Connected Devices List
          _buildSectionHeader('局域网设备', '${discovery.devices.length.toString().padLeft(2, '0')} 在线 / ${discovery.localDeviceName}'),
          const SizedBox(height: 8),
          
          if (discovery.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.radar, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(discovery.isDiscovering ? '正在拼命扫描中...\n(寻找局域网内同一 Wifi 下的设备)' : '点击右下角按钮\n打开局域网可见性', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            )
          else
            ...discovery.devices.map((service) => _buildDeviceCard(
              context: context,
              icon: service.name?.toLowerCase().contains('phone') == true ? Icons.smartphone : Icons.computer,
              name: service.name ?? '未知终端',
              subtitle: service.host != null ? '内网通道: ${service.host}:${service.port}' : '解析通道中...',
              trailingWidget: const Icon(Icons.bolt, color: Colors.green, size: 18),
            )),
          
          const SizedBox(height: 16),

          // 4. Contextual Help Card
          _buildHelpCard(context),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (discovery.isDiscovering) {
            discovery.stopScanning();
          } else {
            discovery.beginScanning();
          }
        },
        backgroundColor: const Color(0xFFD32F2F),
        icon: Icon(discovery.isDiscovering ? Icons.stop : Icons.radar, color: Colors.white),
        label: Text(discovery.isDiscovering ? '停止扫描' : '启动雷达', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMeshStatusHero(BuildContext context, DiscoveryService discovery) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: discovery.isDiscovering ? Colors.green : const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                discovery.isDiscovering ? '本地网状网络 (活跃组网中)' : '本地网状网络',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: discovery.isDiscovering ? Colors.green : const Color(0xFFD32F2F),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            discovery.isDiscovering ? '设备互联进行中' : '雷达待命中',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            discovery.isDiscovering ? '发现 ${discovery.devices.length} 个终端并正在自动建联' : '未开启服务广播。仅当开启时才可见别人。',
            style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: const Color(0xFFD32F2F), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(color: const Color(0xFFE6E8E9), borderRadius: BorderRadius.circular(4.0)),
            child: Text(trailing, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({required BuildContext context, required IconData icon, required String name, required String subtitle, Widget? trailingWidget}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFD32F2F).withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            if (trailingWidget != null) ...[trailingWidget, const SizedBox(width: 8)],
            const Icon(Icons.more_vert, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: const Color(0xFFffdbcb), borderRadius: BorderRadius.circular(12.0)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Color(0xFF9e4300), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('传输提示', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9e4300))),
                SizedBox(height: 4),
                Text('请将设备保持在 10 米以内，以获得最佳网状网络稳定性和最高传输速度。', style: TextStyle(fontSize: 11, color: Color(0xFF9e4300))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
