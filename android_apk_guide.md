# NewCo项目助手 — 部署指南

## 文件结构

```
ProjectHermesApp/
├── backend/
│   └── server.py                  # 后端API服务器（Python标准库，零依赖）
├── flutter_app/
│   ├── pubspec.yaml               # Flutter项目配置
│   ├── lib/
│   │   ├── main.dart              # 入口 + 每日推送
│   │   ├── theme/
│   │   │   └── app_theme.dart     # 主题配色
│   │   ├── screens/
│   │   │   ├── dashboard_page.dart  # 首页看板
│   │   │   ├── report_page.dart     # 进度汇报（聊天式）
│   │   │   ├── history_page.dart    # 历史记录
│   │   │   └── settings_page.dart   # 设置页
│   │   ├── services/
│   │   │   └── api_service.dart     # API调用封装
│   │   └── widgets/
│   │       ├── progress_card.dart   # 进度卡片组件
│   │       └── task_list_tile.dart  # 任务列表项组件
│   └── fonts/                       # 放入中文字体文件
└── android_apk_guide.md             # 此文件
```

---

## 第一步：启动后端服务器（在任何有Python的机器上）

后端是纯Python标准库，零外部依赖，在任何有Python 3.7+的机器上都能跑：

```bash
cd ProjectHermesApp/backend
python3 server.py
```

看到输出：
```
Hermes App Backend running on http://0.0.0.0:8765
API endpoints:
  GET  /api/dashboard  - 首页总览
  POST /api/progress/report - 汇报进度
  ...
```

建议把后端部署在一台长期运行的服务器上（如阿里云¥34/月的轻量服务器），
这样手机App在外面也能连上。

---

## 第二步：编译Flutter APK

### 需要准备

1. **安装Flutter SDK**（Windows/Mac）
   - 下载：[https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
   - 建议装 `flutter 3.x` 版本

2. **中文字体**（因为App里用了中文）
   - 下载 NotoSansSC：[https://fonts.google.com/specimen/Noto+Sans+SC](https://fonts.google.com/specimen/Noto+Sans+SC)
   - 放入 `flutter_app/fonts/NotoSansSC-Regular.ttf`

3. **App图标**（选做）
   - 准备一个 1024x1024 的PNG图标
   - 用 `flutter_launcher_icons` 自动生成各尺寸

### 编译步骤

```bash
# 1. 进入Flutter项目
cd ProjectHermesApp/flutter_app

# 2. 安装依赖
flutter pub get

# 3. 检查项目
flutter doctor

# 4. 编译APK（Android）
flutter build apk --release

# 5. 编译iOS（需要Mac）
flutter build ios --release
```

编译成功后：
- Android APK 在：`build/app/outputs/flutter-apk/app-release.apk`
- iOS 在 Xcode 中 Archive → Export

### 如果编译报错

常见问题：
```
1. "Font not found" → 确认 fonts/NotoSansSC-Regular.ttf 存在
2. "pub get failed" → 检查网络，或 `flutter pub cache repair`
3. "Gradle error" → Flutter项目第一次编译需要下载Gradle，等一会儿
```

---

## 第三步：配置App连接后端

在App的**设置页**中，输入你的后端服务器地址：

| 场景 | 地址 |
|------|------|
| 安卓模拟器（模拟器连宿主机） | `http://10.0.2.2:8765` |
| iOS模拟器（localhost直连） | `http://localhost:8765` |
| 真机+局域网（同一WiFi） | `http://你的电脑IP:8765` |
| 真机+云服务器 | `http://你的服务器IP:8765` |
| 真机+域名 | `https://your-domain.com` |

---

## 第四步：测试

后端启动后，可以用curl测试：

```bash
# 健康检查
curl http://localhost:8765/api/health

# 查看仪表盘
curl http://localhost:8765/api/dashboard

# 汇报进度
curl -X POST http://localhost:8765/api/progress/report \
  -H "Content-Type: application/json" \
  -d '{"text":"BCMA序列拿到了"}'
```

---

## 自定义修改

### 修改App名称
编辑 `flutter_app/android/app/src/main/AndroidManifest.xml`，找到：
```xml
android:label="NewCo项目助手"
```
改成你想要的名称。

### 修改图标
将图标PNG放入 `flutter_app/assets/icon.png`，然后在 `pubspec.yaml` 添加：
```yaml
dev_dependencies:
  flutter_launcher_icons: "^0.13.0"
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
```
运行 `flutter pub get && flutter pub run flutter_launcher_icons`

### 修改推送提醒内容
编辑 `lib/main.dart` 中的 `_scheduleDailyReminder()` 函数的推送文案。

---

## 日常使用流程

```
每天早上 9:00 → App推送提醒 → 打开App看今日待办
           ↓
   做了任务 → 打开App → 汇报页输入"今天X完成了"
           ↓
   Hermes返回建议 → 看板自动更新
           ↓
   想知道下一步 → 汇报页输入"下一步做什么？"
           ↓
   Hermes给出方向建议
```
