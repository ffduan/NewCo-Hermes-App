import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskListTile extends StatelessWidget {
  final String id;
  final String content;
  final String status;
  final String? dueDate;
  final VoidCallback? onTap;

  const TaskListTile({
    super.key,
    required this.id,
    required this.content,
    required this.status,
    this.dueDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = AppTheme.statusLabel(status);
    final icon = AppTheme.statusIcon(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            decoration: status == 'completed'
                ? TextDecoration.lineThrough
                : null,
            color: status == 'completed' ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: dueDate != null
            ? Text('截止：$dueDate',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]))
            : Text(label, style: TextStyle(fontSize: 11, color: color)),
        trailing: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
