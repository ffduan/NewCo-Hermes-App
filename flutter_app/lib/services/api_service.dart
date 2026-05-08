import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 默认本地地址 — 安卓模拟器用 10.0.2.2 映射宿主机 localhost
  // iOS 模拟器直接用 localhost
  // 真机部署时改为你的服务器IP
  String _baseUrl = 'http://10.0.2.2:8765';

  String get baseUrl => _baseUrl;
  set baseUrl(String url) => _baseUrl = url;

  Future<Map<String, dynamic>> get(String path) async {
    final resp = await http.get(Uri.parse('$_baseUrl$path'));
    return json.decode(utf8.decode(resp.bodyBytes));
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return json.decode(utf8.decode(resp.bodyBytes));
  }

  // 首页仪表盘
  Future<Map<String, dynamic>> getDashboard() => get('/api/dashboard');

  // 任务列表
  Future<Map<String, dynamic>> getTasks({String? status}) {
    final qs = status != null ? '?status=$status' : '';
    return get('/api/tasks$qs');
  }

  // 历史记录
  Future<Map<String, dynamic>> getHistory() => get('/api/history');

  // 汇报进度
  Future<Map<String, dynamic>> reportProgress(String text) =>
      post('/api/progress/report', {'text': text});

  // 更新任务状态
  Future<Map<String, dynamic>> updateTask(String id, String status) =>
      post('/api/tasks/update', {'id': id, 'status': status});

  // 请求建议
  Future<Map<String, dynamic>> askAdvice(String question) =>
      post('/api/ask', {'question': question});
}
