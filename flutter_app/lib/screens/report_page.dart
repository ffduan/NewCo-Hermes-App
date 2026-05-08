import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReportPage extends StatefulWidget {
  final ApiService api;
  const ReportPage({super.key, required this.api});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  bool _firstLoad = true;

  // 问候语
  final String _greeting =
      '👋 上午好！今天想汇报什么进度？\n\n'
      '你可以这样说：\n'
      '• "体外验证通过了，表达率45%" \n'
      '• "序列拿到了"\n'
      '• "下一步做什么？"';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({'role': 'hermes', 'text': _greeting});
        _firstLoad = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _sending = true;
    });
    _scrollToBottom();

    try {
      final resp = await widget.api.reportProgress(text);

      // 构建Hermes回复
      final summary = resp['summary'] ?? '已收到';
      final advice = resp['advice'] ?? '';
      final risk = resp['risk'] ?? '';

      String reply = '✅ **$summary**\n\n';
      if (advice.isNotEmpty) {
        reply += '🧭 **下一步建议：**\n$advice\n\n';
      }
      if (risk.isNotEmpty) {
        reply += '⚠️ $risk';
      }

      setState(() {
        _messages.add({'role': 'hermes', 'text': reply});
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'hermes',
          'text': '❌ 连接失败：$e\n请检查后端服务器是否运行。'
        });
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuick(String text) {
    _controller.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('进度汇报')),
      body: Column(
        children: [
          // 快捷按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                _quickChip('下一步做什么？'),
                const SizedBox(width: 8),
                _quickChip('完成了'),
                const SizedBox(width: 8),
                _quickChip('卡住了'),
              ],
            ),
          ),

          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.smart_toy,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppTheme.accentColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomLeft: isUser
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottomRight: isUser
                                        ? Radius.zero
                                        : const Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isUser ? Colors.white : Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 加载指示
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          // 输入框
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: '输入进度或问题...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _sending
                      ? Colors.grey
                      : AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => _sendQuick(label),
    );
  }
}
