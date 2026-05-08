import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoryPage extends StatefulWidget {
  final ApiService api;
  const HistoryPage({super.key, required this.api});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getHistory();
      setState(() {
        _entries = List<Map<String, dynamic>>.from(data['entries'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('M/d HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('还没有进度记录', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      final userText = e['user_text'] ?? '';
                      final hermesRaw = e['hermes_response'] ?? '';
                      final createdAt = e['created_at'] ?? '';
                      final dateStr = _formatDate(createdAt);
                      final dateLabel = _dateLabel(createdAt);

                      // 尝试解析hermes_response
                      String hermesText = '';
                      try {
                        final parsed = hermesRaw is String
                            ? (hermesRaw.startsWith('{')
                                ? Map<String, dynamic>.from(
                                    // ignore: avoid_dynamic_calls
                                    (hermesRaw as String).contains('{')
                                        ? {}
                                        : {})
                                : {})
                            : {};
                        hermesText = parsed['summary'] ?? '';
                      } catch (_) {
                        hermesText = hermesRaw;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            radius: 18,
                            child: Text(dateStr.split(' ')[0].split('/').last,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                          title: Text(
                            userText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Row(
                            children: [
                              Text(dateStr,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                              if (dateLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(dateLabel,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.accentColor)),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 20),
                          onTap: () => _showDetail(userText, hermesRaw, createdAt),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _dateLabel(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return '今天';
      if (diff.inDays == 1) return '昨天';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '';
    } catch (_) {
      return '';
    }
  }

  void _showDetail(String userText, String hermesRaw, String createdAt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('进度详情', style: Theme.of(ctx).textTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🕐 $_formatDate(createdAt)',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 12),
            const Text('你的汇报：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(userText),
            const SizedBox(height: 16),
            const Text('Hermes回复：',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(hermesRaw.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
