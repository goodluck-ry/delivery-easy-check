import 'package:flutter/material.dart';

import 'app_config.dart';
import 'screens/account_screen.dart';
import 'screens/express_list_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_store.dart';
import 'services/settings_store.dart';

void main() async {
  // shared_preferences 需要先初始化 binding
  WidgetsFlutterBinding.ensureInitialized();
  await authStore.init();
  await settingsStore.init();
  runApp(const CampusExpressApp());
}

class CampusExpressApp extends StatelessWidget {
  const CampusExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '看看你递',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 带底部导航的应用骨架，切换"我的快递"和"账号设置"两个页
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // 页面常驻，切换时不重建。
  // 账号 tab 受 ENABLE_BIND_FLOW 开关控制：关闭时（发布包）整个 tab 不显示，
  // 后续做娱乐功能时打开 define 即恢复。
  List<Widget> get _pages => [
        const ExpressListScreen(),
        if (AppConfig.enableBindFlow) const AccountScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '我的快递',
          ),
          if (AppConfig.enableBindFlow)
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '账号',
            ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
