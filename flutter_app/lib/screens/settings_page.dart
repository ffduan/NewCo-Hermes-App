import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _serverController = TextEditingController();
  ApiService? _api;

  @override
  void initState() {
    super.initState();
    // 尝试从父级获取ApiService，或者用默认值
    _serverController = TextEditingController(text: 'http://localhost:8765');
    // 延迟一帧尝试拿到父级路由的api
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryFindApi();
    });
  }

  void _tryFindApi() {
    try {
      // 通过MainScreen传递的api - 暂时用默认值
    } catch (_) {}
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _saveAndApply() {
    final url = _serverController.text.trim();
    if (url.isEmpty) {
      _showSnack('请输入服务器地址');
      return;
    }
    // 保存到共享内存（通过静态变量）
    ApiService.defaultBaseUrl = url;
    _showSnack('✅ 服务器地址已保存: $url');
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      Text('服务器连接', style: Theme.of(context).textTheme.titleSmall),
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
                      onPressed: _saveAndApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('保存并应用'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '修改后请回到看板页下拉刷新',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                      Text('关于', style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    title: Text('NewCo项目助手', style: TextStyle(fontSize: 14)),
                    subtitle: Text('v1.0.1 · 服务器地址可保存',
                        style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const ListTile(
                    title: Text('使用说明', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '1. 设置页输入服务器地址 → 保存\n'
                      '2. 回到看板页下拉刷新\n'
                      '3. 在「汇报」页输入进度',
                      style: TextStyle(fontSize: 12),
                    ),
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
