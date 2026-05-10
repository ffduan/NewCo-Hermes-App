import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_list_tile.dart';

class DashboardPage extends StatefulWidget {
  final ApiService api;
  const DashboardPage({super.key, required this.api});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getDashboard();
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '连接后端失败：$e\n请确保后端服务器已启动';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NewCo项目')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text('尝试连接: ${widget.api.baseUrl}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final phase = _data!['current_phase'] ?? '阶段0';
    final progress = (_data!['progress_pct'] as num?)?.toDouble() ?? 0;
    final stats = _data!['stats'] as Map? ?? {};
    final todayTasks = _data!['today_tasks'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        // 阶段进度卡片
        ProgressCard(
          phase: phase,
          progress: progress,
          total: stats['total'] ?? 0,
          completed: stats['completed'] ?? 0,
          inProgress: stats['in_progress'] ?? 0,
          pending: stats['pending'] ?? 0,
        ),
        const SizedBox(height: 12),

        // 本周目标
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, size: 18, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    Text('本周目标', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '完成BCMA CAR mRNA体外验证 + 启动CD7-LNP偶联',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 今日待办
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.today, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('今日待办', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text('${todayTasks.length}项',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        ...todayTasks.map((t) => TaskListTile(
          id: t['id'] ?? '',
          content: t['content'] ?? '',
          status: t['status'] ?? 'pending',
          dueDate: t['due_date'],
          onTap: () => _showTaskAction(t['id'], t['status']),
        )),

        const SizedBox(height: 24),
        // 底部刷新提示
        Center(
          child: Text('下拉刷新',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
      ],
    );
  }

  void _showTaskAction(String id, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
              title: const Text('标记为已完成'),
              onTap: () async {
                await widget.api.updateTask(id, 'completed');
                Navigator.pop(ctx);
                _load();
              },
            ),
            if (currentStatus != 'in_progress')
              ListTile(
                leading: const Icon(Icons.sync, color: AppTheme.inProgressColor),
                title: const Text('标记为进行中'),
                onTap: () async {
                  await widget.api.updateTask(id, 'in_progress');
                  Navigator.pop(ctx);
                  _load();
                },
              ),
            if (currentStatus != 'pending')
              ListTile(
                leading: const Icon(Icons.undo, color: AppTheme.pendingColor),
                title: const Text('重置为待办'),
                onTap: () async {
                  await widget.api.updateTask(id, 'pending');
                  Navigator.pop(ctx);
                  _load();
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
