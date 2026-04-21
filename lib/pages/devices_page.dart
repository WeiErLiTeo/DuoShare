import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/discovery_service.dart';
import '../services/connection_service.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryService>();
    final connection = context.watch<ConnectionService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          // 1. Mesh Status Hero
          _buildMeshStatusHero(context, discovery, connection),
          const SizedBox(height: 12),

          // 2. Stats Grid
          Row(
            children: [
              Expanded(child: _buildStatCard(context, Icons.link, '已连接', '${connection.connectedPeers.length} 台设备')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, Icons.cell_tower, '服务端口', connection.isRunning ? '${connection.serverPort}' : '未启动')),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Connected Devices List
          if (connection.connectedPeers.isNotEmpty) ...[
            _buildSectionHeader('已连接设备', '${connection.connectedPeers.length.toString().padLeft(2, '0')} 已连接'),
            const SizedBox(height: 8),
            ...connection.connectedPeers.map((name) => _buildDeviceCard(
              context: context,
              icon: Icons.devices,
              name: name,
              subtitle: 'WebSocket 通道已建立',
              trailingWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => connection.disconnectPeer(name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('断开', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],

          // 4. Discovered Devices (from mDNS)
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
            ...discovery.devices.map((service) {
              final isConnected = connection.isConnectedTo(service.name ?? '');
              return _buildDeviceCard(
                context: context,
                icon: service.name?.toLowerCase().contains('phone') == true ? Icons.smartphone : Icons.computer,
                name: service.name ?? '未知终端',
                subtitle: service.host != null ? '${service.host}:${service.port}' : '解析通道中...',
                trailingWidget: isConnected
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : _buildConnectButton(context, discovery, service),
              );
            }),
          
          const SizedBox(height: 16),

          // 5. Contextual Help Card
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

  Widget _buildConnectButton(BuildContext context, DiscoveryService discovery, dynamic service) {
    return InkWell(
      onTap: () async {
        final success = await discovery.connectToDevice(service);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success ? '已连接到 ${service.name}' : '连接失败'),
            backgroundColor: success ? Colors.green : const Color(0xFFD32F2F),
            duration: const Duration(seconds: 2),
          ));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('连接', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildMeshStatusHero(BuildContext context, DiscoveryService discovery, ConnectionService connection) {
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
                  color: connection.connectedPeers.isNotEmpty ? Colors.green : (discovery.isDiscovering ? Colors.orange : const Color(0xFFD32F2F)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connection.connectedPeers.isNotEmpty
                    ? '网状网络 (${connection.connectedPeers.length} 台设备已连接)'
                    : (discovery.isDiscovering ? '正在搜索设备...' : '本地网状网络'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: connection.connectedPeers.isNotEmpty ? Colors.green : (discovery.isDiscovering ? Colors.orange : const Color(0xFFD32F2F)),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            connection.connectedPeers.isNotEmpty
                ? '设备互联中'
                : (discovery.isDiscovering ? '雷达扫描中' : '雷达待命中'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            connection.connectedPeers.isNotEmpty
                ? '已建立 WebSocket 双向通道，可以互传数据了'
                : (discovery.isDiscovering ? '发现 ${discovery.devices.length} 个终端，点击"连接"建立通道' : '点击下方按钮开始扫描局域网设备'),
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
          Expanded(
            child: Column(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
            if (trailingWidget != null) trailingWidget,
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
