#!/usr/bin/env python3
"""
Hermes App Backend — 零外部依赖
使用 Python 标准库 http.server + sqlite3 + json
"""

import http.server
import json
import sqlite3
import os
import urllib.parse
import subprocess
import threading
import time
from datetime import datetime, date

# ============================
# 数据库初始化
# ============================
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hermes_app.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.executescript("""
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            category TEXT DEFAULT '',
            phase TEXT DEFAULT '0',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            due_date TEXT,
            note TEXT
        );
        CREATE TABLE IF NOT EXISTS progress_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_text TEXT NOT NULL,
            hermes_response TEXT,
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS project_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
    """)
    conn.commit()
    conn.close()

# ============================
# 默认任务数据
# ============================
DEFAULT_TASKS = [
    ("t1", "BCMA CAR mRNA: scFv序列获取与人源化", "pending", "分子构建", "0"),
    ("t2", "BCMA CAR mRNA: mRNA模板质粒设计合成", "pending", "分子构建", "0"),
    ("t3", "BCMA CAR mRNA: IVT体外转录+修饰核苷酸", "pending", "分子构建", "0"),
    ("t4", "BCMA CAR mRNA: 体外电转染+流式验证CAR表达", "pending", "分子构建", "0"),
    ("t5", "BCMA CAR mRNA: 体外杀伤功能验证", "pending", "分子构建", "0"),
    ("t6", "CD7配体: 序列确认+表达纯化", "pending", "CD7-LNP", "0"),
    ("t7", "CD7-LNP偶联: 与Factor对接完成偶联小试", "pending", "CD7-LNP", "0"),
    ("t8", "CD7-LNP偶联: 体外靶向转染验证", "pending", "CD7-LNP", "0"),
    ("t9", "CD7-LNP: 小鼠交叉反应性测试", "pending", "CD7-LNP", "0"),
    ("t10", "FTO专利分析: 初步筛查Capstan/Arbutus专利", "pending", "法务", "0"),
    ("t11", "Bridge文档: Senlang gMG数据作为IND桥接论据", "pending", "监管", "0"),
    ("t12", "IIT: 方案撰写+伦理审批准备", "pending", "临床", "0"),
    ("t13", "融资: 种子轮BP + 投资人列表", "pending", "融资", "0"),
    ("t14", "团队: CTO/CSO人选确认", "pending", "团队", "0"),
]

def seed_tasks():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    existing = c.execute("SELECT COUNT(*) FROM tasks").fetchone()[0]
    if existing == 0:
        now = datetime.now().isoformat()
        for t in DEFAULT_TASKS:
            c.execute(
                "INSERT INTO tasks (id, content, status, category, phase, created_at, updated_at) VALUES (?,?,?,?,?,?,?)",
                (t[0], t[1], t[2], t[3], t[4], now, now)
            )
        c.execute("INSERT OR IGNORE INTO project_state (key, value, updated_at) VALUES (?,?,?)",
                  ("current_phase", "阶段0：分子构建与验证", now))
        conn.commit()
    conn.close()

# ============================
# API 处理器
# ============================
class HermesAPI(http.server.BaseHTTPRequestHandler):
    
    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
    
    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))
    
    def do_OPTIONS(self):
        self._send_json({"ok": True})
    
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        
        if path == "/api/dashboard":
            self._handle_dashboard()
        elif path == "/api/tasks":
            self._handle_get_tasks(parsed.query)
        elif path == "/api/history":
            self._handle_get_history()
        elif path == "/api/health":
            self._send_json({"status": "ok", "time": datetime.now().isoformat()})
        else:
            self._send_json({"error": "not found"}, 404)
    
    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        body = self._read_body()
        
        if path == "/api/progress/report":
            self._handle_report(body)
        elif path == "/api/tasks/update":
            self._handle_update_task(body)
        elif path == "/api/ask":
            self._handle_ask(body)
        else:
            self._send_json({"error": "not found"}, 404)
    
    # ---------- 首页仪表盘 ----------
    def _handle_dashboard(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # 当前阶段
        phase_row = c.execute("SELECT value FROM project_state WHERE key='current_phase'").fetchone()
        current_phase = phase_row[0] if phase_row else "阶段0"
        
        # 任务统计
        total = c.execute("SELECT COUNT(*) FROM tasks").fetchone()[0]
        completed = c.execute("SELECT COUNT(*) FROM tasks WHERE status='completed'").fetchone()[0]
        in_progress = c.execute("SELECT COUNT(*) FROM tasks WHERE status='in_progress'").fetchone()[0]
        pending = c.execute("SELECT COUNT(*) FROM tasks WHERE status='pending'").fetchone()[0]
        
        # 今日任务（最近更新的前5个未完成）
        today_tasks = c.execute(
            "SELECT id, content, status, due_date FROM tasks WHERE status != 'completed' ORDER BY updated_at DESC LIMIT 5"
        ).fetchall()
        
        conn.close()
        
        progress_pct = round(completed / total * 100, 1) if total > 0 else 0
        
        self._send_json({
            "current_phase": current_phase,
            "progress_pct": progress_pct,
            "stats": {"total": total, "completed": completed, "in_progress": in_progress, "pending": pending},
            "today_tasks": [
                {"id": t[0], "content": t[1], "status": t[2], "due_date": t[3]} for t in today_tasks
            ]
        })
    
    # ---------- 任务列表 ----------
    def _handle_get_tasks(self, query):
        params = urllib.parse.parse_qs(query)
        status_filter = params.get("status", [None])[0]
        
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        if status_filter:
            rows = c.execute("SELECT id, content, status, category, phase, due_date, note FROM tasks WHERE status=? ORDER BY id", (status_filter,)).fetchall()
        else:
            rows = c.execute("SELECT id, content, status, category, phase, due_date, note FROM tasks ORDER BY id").fetchall()
        
        conn.close()
        
        self._send_json({
            "tasks": [
                {"id": r[0], "content": r[1], "status": r[2], "category": r[3],
                 "phase": r[4], "due_date": r[5], "note": r[6]} for r in rows
            ]
        })
    
    # ---------- 历史记录 ----------
    def _handle_get_history(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        rows = c.execute("SELECT id, user_text, hermes_response, created_at FROM progress_logs ORDER BY created_at DESC LIMIT 50").fetchall()
        conn.close()
        
        self._send_json({
            "entries": [
                {"id": r[0], "user_text": r[1], "hermes_response": r[2], "created_at": r[3]} for r in rows
            ]
        })
    
    # ---------- 进度汇报 ----------
    def _handle_report(self, body):
        user_text = body.get("text", "")
        if not user_text:
            self._send_json({"error": "text is required"}, 400)
            return
        
        now = datetime.now().isoformat()
        
        # 调用Hermes获取建议
        hermes_response = self._call_hermes(user_text)
        
        # 保存到数据库
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute(
            "INSERT INTO progress_logs (user_text, hermes_response, created_at) VALUES (?,?,?)",
            (user_text, json.dumps(hermes_response, ensure_ascii=False), now)
        )
        c.execute("UPDATE project_state SET value=?, updated_at=? WHERE key='current_phase'",
                  (hermes_response.get("phase", "阶段0"), now))
        conn.commit()
        conn.close()
        
        self._send_json({
            "status": "ok",
            "summary": hermes_response.get("summary", "已收到"),
            "advice": hermes_response.get("advice", ""),
            "tasks_updated": hermes_response.get("tasks_updated", []),
            "risk": hermes_response.get("risk", ""),
            "phase": hermes_response.get("phase", "阶段0")
        })
    
    # ---------- 更新任务状态 ----------
    def _handle_update_task(self, body):
        task_id = body.get("id")
        new_status = body.get("status")
        
        if not task_id or not new_status:
            self._send_json({"error": "id and status required"}, 400)
            return
        
        now = datetime.now().isoformat()
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("UPDATE tasks SET status=?, updated_at=? WHERE id=?", (new_status, now, task_id))
        conn.commit()
        conn.close()
        
        self._send_json({"status": "ok", "task_id": task_id, "new_status": new_status})
    
    # ---------- 方向建议 ----------
    def _handle_ask(self, body):
        question = body.get("question", "")
        if not question:
            self._send_json({"error": "question is required"}, 400)
            return
        
        response = self._call_hermes(f"用户问：{question}")
        
        self._send_json({
            "status": "ok",
            "advice": response.get("advice", ""),
            "priority": response.get("priority", []),
            "summary": response.get("summary", "")
        })
    
    # ---------- Hermes调用（模拟，实际对接CLI） ----------
    def _call_hermes(self, user_text):
        """调用Hermes CLI获取结构化反馈。
        生产环境：替换为真正的subprocess调用 hermes CLI
        当前：使用基于规则的语义分析"""
        
        text_lower = user_text.lower()
        
        # 简单规则引擎 - 识别关键词
        phase = "阶段0：分子构建与验证"
        summary = "已收到汇报"
        advice_lines = []
        tasks_updated = []
        risk = ""
        
        # 检测是否在汇报完成情况
        if any(k in user_text for k in ["完成", "通过", "done", "验证", "拿到了", "拿到", "OK"]):
            if "序列" in user_text or "scfv" in text_lower or "scFv" in user_text or "bcma" in text_lower:
                summary = "BCMA scFv序列获取完成"
                advice_lines = [
                    "下一步：将序列提交给生物信息学团队做mRNA密码子优化",
                    "同步启动mRNA模板质粒的合成询价（IDT或GeneArt）",
                    "开始设计CD7配体的表达纯化实验方案"
                ]
                tasks_updated = ["t1"]
            elif "体外" in user_text and ("验证" in user_text or "表达" in user_text):
                summary = "BCMA CAR mRNA体外验证通过"
                advice_lines = [
                    "下一步：启动CD7配体表达纯化（找金斯瑞或义翘神州报价）",
                    "与Factor联系确认CD7-LNP偶联的技术方案和时间线",
                    "同步开始小鼠交叉反应性测试的抗原准备"
                ]
                tasks_updated = ["t4", "t5"]
            elif "cd7" in text_lower or "配体" in user_text or "表达" in user_text:
                summary = "CD7配体表达纯化完成"
                advice_lines = [
                    "下一步：将纯化后的CD7配体寄给Factor做LNP偶联",
                    "同时启动CD7配体与小鼠CD7的交叉反应性ELISA",
                    "设计体外靶向转染验证的实验方案"
                ]
                tasks_updated = ["t6"]
            elif "偶联" in user_text:
                summary = "CD7-LNP偶联小试完成"
                advice_lines = [
                    "下一步：立即做体外靶向转染验证（T细胞 vs 非靶向对照）",
                    "启动NHP必要性评估讨论"
                ]
                tasks_updated = ["t7"]
            else:
                advice_lines = ["确认收到进度更新", "继续保持当前节奏"]
        elif "问题" in user_text or "卡住" in user_text or "blocker" in text_lower or "不行" in user_text:
            summary = "收到阻塞报告"
            advice_lines = [
                "分析阻塞原因并提供替代方案",
                "如果涉及外包delay，考虑备选CRO",
                "如果涉及技术问题，建议召开技术讨论会"
            ]
            risk = "⚠️ 当前有阻塞项，需要优先解决"
        elif "下一步" in user_text or "建议" in user_text or "方向" in user_text or "?" in user_text:
            summary = "方向建议请求"
            advice_lines = [
                "当前优先级：",
                "P0 - BCMA CAR mRNA体外验证（4周内必须完成）",
                "P1 - CD7配体表达纯化和LNP偶联（与P0并行）",
                "P2 - 小鼠体内概念验证（准备阶段）"
            ]
        
        # 如果没有任何匹配，给出通用建议
        if not advice_lines:
            advice_lines = [
                "已收到，继续关注核心里程碑：BCMA CAR mRNA验证 + CD7-LNP偶联"
            ]
        
        return {
            "summary": summary,
            "advice": "\n".join(advice_lines),
            "tasks_updated": tasks_updated,
            "risk": risk,
            "phase": phase
        }


# ============================
# 启动服务器
# ============================
def run_server(port=8765):
    init_db()
    seed_tasks()
    
    server = http.server.HTTPServer(("0.0.0.0", port), HermesAPI)
    print(f"Hermes App Backend running on http://0.0.0.0:{port}")
    print(f"API endpoints:")
    print(f"  GET  /api/dashboard  - 首页总览")
    print(f"  GET  /api/tasks      - 任务列表")
    print(f"  GET  /api/history    - 历史记录")
    print(f"  POST /api/progress/report - 汇报进度")
    print(f"  POST /api/tasks/update    - 更新任务状态")
    print(f"  POST /api/ask        - 请求建议")
    print(f"  GET  /api/health     - 健康检查")
    print(f"\n使用: curl http://localhost:{port}/api/health")
    server.serve_forever()

if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    run_server(port)
