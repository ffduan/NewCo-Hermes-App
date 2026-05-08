import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _serverController = TextEditingController();
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: 'http://10.0.2.2:8765');
    _loadPrefs();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverController.text =
          prefs.getString('server_url') ?? 'http://10.0.2.2:8765';
      _reminderHour = prefs.getInt('reminder_hour') ?? 9;
      _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
      _notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveServer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址已保存')),
      );
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (time != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', time.hour);
      await prefs.setInt('reminder_minute', time.minute);
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('每日提醒时间已设为 ${time.hour}:${time.minute.toString().padLeft(2, '0')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 服务器连接
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, size: 18, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text('服务器连接',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    decoration: InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'http://your-server:8765',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 通知设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, size: 18, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text('通知设置',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('每日督促通知', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('每天早上推送进度提醒',
                        style: TextStyle(fontSize: 12)),
                    value: _notificationsEnabled,
                    onChanged: (v) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', v);
                      setState(() => _notificationsEnabled = v);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    title: const Text('提醒时间', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                        '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.access_time),
                    contentPadding: EdgeInsets.zero,
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 关于
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, size: 18, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text('关于',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    title: Text('NewCo项目助手', style: TextStyle(fontSize: 14)),
                    subtitle: Text('v1.0.0 · Powered by Hermes Agent',
                        style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const ListTile(
                    title: Text('数据存储', style: TextStyle(fontSize: 14)),
                    subtitle: Text('所有数据存储在后端服务器本地数据库',
                        style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
