import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_page.dart';
import 'screens/report_page.dart';
import 'screens/history_page.dart';
import 'screens/settings_page.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地通知
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 设置每日9:00提醒
  await _scheduleDailyReminder();

  runApp(const HermesApp());
}

Future<void> _scheduleDailyReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final hour = prefs.getInt('reminder_hour') ?? 9;
  final minute = prefs.getInt('reminder_minute') ?? 0;

  // 安卓定时通知
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'daily_reminder',
    '每日督促',
    channelDescription: '每天早上推送项目进度提醒',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  // 使用 periodic 模拟每日提醒（实际生产环境用 workmanager）
  await flutterLocalNotificationsPlugin.periodicallyShow(
    0,
    '☀️ NewCo项目 · 每日进度检查',
    '新的一天开始了，今天要推进什么？打开App查看任务清单。',
    RepeatInterval.daily,
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewCo项目助手',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ApiService _api = ApiService();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      DashboardPage(api: _api),
      ReportPage(api: _api),
      HistoryPage(api: _api),
      const SettingsPage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '看板'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '汇报'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
