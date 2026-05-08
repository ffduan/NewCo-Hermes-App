import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressCard extends StatelessWidget {
  final String phase;
  final double progress;
  final int total;
  final int completed;
  final int inProgress;
  final int pending;

  const ProgressCard({
    super.key,
    required this.phase,
    required this.progress,
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(phase,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ),
                const Spacer(),
                Text('$progress%',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
            const SizedBox(height: 16),
            // 统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('总计', total.toString(), Colors.grey[600]!),
                _statItem('已完成', completed.toString(), AppTheme.successColor),
                _statItem('进行中', inProgress.toString(), AppTheme.inProgressColor),
                _statItem('待办', pending.toString(), AppTheme.pendingColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
