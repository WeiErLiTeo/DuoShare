import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/devices_page.dart';
import 'pages/clipboard_page.dart';
import 'pages/files_page.dart';
import 'pages/messages_page.dart';
import 'pages/settings_page.dart';
import 'services/discovery_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiscoveryService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuoShare',
      debugShowCheckedModeBanner: false,
      theme: _buildJapaneseRedWhiteTheme(),
      home: const ResponsiveScaffold(),
    );
  }

  // 全局红白主题 (ThemeData)
  ThemeData _buildJapaneseRedWhiteTheme() {
    return ThemeData(
      useMaterial3: false, // 遵循 Android 10 (Material 2) 风格
      primaryColor: const Color(0xFFD32F2F), // 日式红
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // 纯白背景
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD32F2F),
        secondary: Color(0xFFD32F2F),
        surface: Color(0xFFFFFFFF),
      ),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF), // AppBar 背景与页面融合
        foregroundColor: Color(0xFFD32F2F), // 标题颜色
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 1.0, // 极小阴影
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      ),
    );
  }
}

// 响应式导航壳子 (Scaffold)
class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({Key? key}) : super(key: key);

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DevicesPage(),
    const FilesPage(),
    const MessagesPage(),
    const ClipboardPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_shared, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('DuoShare',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFFD32F2F)),
            onPressed: () {},
          )
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme:
                      const IconThemeData(color: Color(0xFFD32F2F)),
                  selectedLabelTextStyle: const TextStyle(
                      color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(Icons.devices), label: Text('设备')),
                    NavigationRailDestination(
                        icon: Icon(Icons.folder_open), label: Text('文件')),
                    NavigationRailDestination(
                        icon: Icon(Icons.chat_bubble), label: Text('消息')),
                    NavigationRailDestination(
                        icon: Icon(Icons.content_paste), label: Text('剪贴板')),
                    NavigationRailDestination(
                        icon: Icon(Icons.settings), label: Text('设置')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _pages[_selectedIndex]),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFD32F2F),
              unselectedItemColor: Colors.black54,
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 4.0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.devices), label: '设备'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.folder_open), label: '文件'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble), label: '消息'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.content_paste), label: '剪贴板'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: '设置'),
              ],
            ),
    );
  }
}
