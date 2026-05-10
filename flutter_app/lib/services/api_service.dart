import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 单例
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  String _baseUrl = 'http://127.0.0.1:8765';

  ApiService._internal();

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final url = '$_baseUrl$path';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    }
    return json.decode(utf8.decode(resp.bodyBytes));
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = '$_baseUrl$path';
    final resp = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    }
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
