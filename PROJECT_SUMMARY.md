# SoulNote 项目总览

## 📦 项目结构

```
doc_self2/
├── lib/                          # 源代码目录
│   ├── main.dart                # 应用入口
│   ├── theme/                   # 主题配置
│   │   └── app_theme.dart      # 深色主题和颜色定义
│   └── screens/                 # 界面文件
│       ├── main_navigation.dart      # 底部导航栏
│       ├── note_stream_screen.dart   # 笔记流界面
│       ├── sync_radar_screen.dart    # 设备同步雷达
│       ├── search_screen.dart        # 搜索界面
│       └── settings_screen.dart      # 设置界面
├── assets/                      # 资源文件
│   └── images/                 # 图片资源
├── ios/                        # iOS 配置
│   └── Runner/
│       └── Info.plist          # iOS 权限配置
├── test/                       # 测试文件
│   └── widget_test.dart       # 基础测试
├── pubspec.yaml               # Flutter 项目配置
├── analysis_options.yaml      # 代码分析配置
├── README.md                  # 项目说明
├── QUICKSTART.md             # 快速入门
├── FEATURES.md               # 功能详解
└── PROJECT_SUMMARY.md        # 本文件
```

## 🎯 核心文件说明

### lib/main.dart
- 应用入口点
- 配置状态栏样式
- 注入主题
- 设置主页为 MainNavigation

### lib/theme/app_theme.dart
- 定义颜色常量
  - 主色：#137FEC（蓝色）
  - 背景色：#101922（深灰）
  - 卡片色：#1C2632（灰蓝）
- 配置 Material Design 3 主题
- 使用 Google Fonts (Inter 字体)

### lib/screens/main_navigation.dart
- 底部标签导航
- 管理三个主要页面的切换
- iOS 风格的标签栏
- 页面状态管理

### lib/screens/note_stream_screen.dart
- 笔记流主界面
- 消息气泡展示
- 支持文本和图片
- 底部输入框
- 同步状态显示
- 从 HTML 中热链接的图片

### lib/screens/sync_radar_screen.dart
- 可视化同步雷达
- 自定义动画绘制
- 雷达扫描效果
- 设备列表
- 同步进度显示

### lib/screens/search_screen.dart
- 本地笔记搜索
- 标签高亮
- 搜索结果卡片
- 加密搜索提示

### lib/screens/settings_screen.dart
- 设备身份管理
- 存储空间查看
- 自动同步开关
- 数据删除确认

## 🎨 设计系统

### 颜色规范
```dart
Primary Color:   #137FEC  // 主色（蓝）
Background Dark: #101922  // 深色背景
Card Dark:       #1C2632  // 卡片背景
Border Dark:     #283039  // 边框颜色
```

### 组件规范
- **圆角**: 16px (标准), 24px (输入框/按钮)
- **字体**: Inter (Google Fonts)
- **图标**: Material Icons
- **间距**: 8px, 12px, 16px, 24px

### 动画效果
- 脉冲动画：2 秒循环
- 雷达扫描：3 秒循环
- 旋转进度：持续动画
- 页面切换：淡入淡出

## 📱 界面架构

```
MainNavigation
├── NoteStreamScreen (默认)
│   ├── AppBar (顶部栏 + P2P 状态)
│   ├── ListView (笔记列表)
│   └── InputBar (输入框)
│   └── → SyncRadarScreen (点击 P2P Active)
├── SearchScreen
│   ├── SearchBar (搜索框)
│   └── ResultsList (搜索结果)
└── SettingsScreen
    ├── Identity Section
    ├── Connectivity Section
    └── Danger Zone
```

## 🔧 依赖包

### 生产依赖
- `flutter`: Flutter SDK
- `cupertino_icons`: iOS 图标
- `google_fonts`: Inter 字体
- `intl`: 日期时间格式化

### 开发依赖
- `flutter_test`: 测试框架
- `flutter_lints`: 代码规范检查

## 🚀 快速开始

### 1. 安装依赖
```bash
cd /Users/corn/project/own/doc_self2
flutter pub get
```

### 2. 运行应用
```bash
# iOS 模拟器
flutter run

# 或指定设备
flutter run -d "iPhone 15 Pro"
```

### 3. 检查代码
```bash
# 代码分析
flutter analyze

# 运行测试
flutter test
```

## 📊 代码统计

### 文件数量
- Dart 文件: 7 个
- 总代码行数: ~1500 行
- 注释和文档: ~200 行

### 组件统计
- 自定义 Widget: 30+
- 动画控制器: 1 个
- 自定义 Painter: 1 个

## 🎯 特色实现

### 1. 雷达动画 (sync_radar_screen.dart)
```dart
class RadarPainter extends CustomPainter {
  // 自定义绘制雷达圆环
  // 动画脉冲效果
}
```

### 2. 标签高亮 (search_screen.dart)
```dart
Widget _buildHighlightedText() {
  // 动态解析标签
  // 应用不同样式
}
```

### 3. 状态管理
- 使用 StatefulWidget
- setState 更新 UI
- TextEditingController 管理输入

## 🔐 隐私设计

### 本地存储（规划）
- SQLite 数据库
- 加密密钥存储
- 安全删除机制

### P2P 同步（规划）
- 蓝牙低功耗 (BLE)
- 增量同步算法
- 冲突解决策略

## 📝 开发规范

### 命名规范
- 文件名: `snake_case.dart`
- 类名: `PascalCase`
- 变量/方法: `camelCase`
- 常量: `camelCase` 或 `UPPER_CASE`

### 代码风格
- 使用 `flutter_lints`
- 优先使用 `const` 构造函数
- 避免过深的嵌套
- 添加必要的注释

## 🔄 版本管理

### 当前版本
- **版本号**: 1.0.0+1
- **状态**: UI 演示版本
- **平台**: iOS

### 版本历史
- v1.0.0 - 初始版本，完整 UI 实现

## 🎯 后续开发

### Phase 1: 数据层 (2-3 周)
- [ ] 集成 sqflite
- [ ] 实现数据模型
- [ ] 本地 CRUD 操作
- [ ] 数据迁移

### Phase 2: 同步功能 (3-4 周)
- [ ] 集成蓝牙库
- [ ] P2P 连接管理
- [ ] 同步协议实现
- [ ] 冲突解决

### Phase 3: 安全加密 (2 周)
- [ ] 端到端加密
- [ ] 密钥管理
- [ ] 安全存储

### Phase 4: 高级功能 (按需)
- [ ] Markdown 支持
- [ ] 语音笔记
- [ ] 标签系统
- [ ] 导出功能

## 💡 提示和技巧

### 开发技巧
1. 使用热重载 (按 `r`) 快速预览
2. 使用 DevTools 调试布局问题
3. 使用 Flutter Inspector 检查 Widget 树
4. 使用 Performance Overlay 监控性能

### 调试命令
```bash
# 查看设备列表
flutter devices

# 查看日志
flutter logs

# 清理构建
flutter clean

# 更新依赖
flutter pub upgrade
```

## 📚 学习资源

### Flutter 官方
- [Flutter 文档](https://flutter.dev/docs)
- [Widget 目录](https://flutter.dev/docs/development/ui/widgets)
- [Cookbook](https://flutter.dev/docs/cookbook)

### Material Design
- [Material Design 3](https://m3.material.io/)
- [Color System](https://m3.material.io/styles/color/overview)

### 社区资源
- [Pub.dev](https://pub.dev/) - Dart 包仓库
- [Flutter Community](https://fluttercommunity.dev/)

## 🙏 鸣谢

本项目的 UI 设计参考了提供的 HTML 原型，使用 Flutter 完整实现。

---

**项目状态**: ✅ UI 完成，待实现后端功能

**最后更新**: 2026-01-18
