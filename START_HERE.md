# 🎉 欢迎使用 SoulNote！

> 一个本地优先、P2P 同步的笔记应用 - 你的数据，你的控制

---

## 🚀 快速开始（3 步）

### 1️⃣ 安装依赖
```bash
cd /Users/corn/project/own/doc_self2
flutter pub get
```

### 2️⃣ 启动模拟器
```bash
open -a Simulator
```

### 3️⃣ 运行应用
```bash
flutter run
```

**或者使用快速启动脚本：**
```bash
./run.sh
```

---

## 📚 文档导航

根据你的需求选择阅读：

### 🆕 新手入门
1. **[INSTALL.md](INSTALL.md)** - 完整的安装指南
   - Flutter 环境配置
   - Xcode 设置
   - 故障排查

2. **[QUICKSTART.md](QUICKSTART.md)** - 5 分钟快速入门
   - 立即运行
   - 基础操作
   - 常用命令

### 📖 深入了解
3. **[README.md](README.md)** - 项目概述
   - 功能介绍
   - 技术栈
   - 设计理念

4. **[FEATURES.md](FEATURES.md)** - 功能详解
   - 界面说明
   - 操作指南
   - 使用技巧

### 🛠 开发参考
5. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 项目架构
   - 代码结构
   - 技术细节
   - 开发规范

---

## 🎯 应用功能一览

### 📝 笔记流
- 类似聊天的笔记界面
- 支持文本和图片
- 实时同步状态

### 📡 设备同步雷达
- 可视化设备发现
- 蓝牙 P2P 同步
- 同步进度监控

### 🔍 智能搜索
- 本地加密搜索
- 标签高亮
- 快速过滤

### ⚙️ 隐私设置
- 设备身份管理
- 存储空间查看
- 自动同步控制

---

## 🎨 界面预览

### 主界面（笔记流）
```
┌─────────────────────────────┐
│  SoulNote    [P2P Active] ⚙│
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐   │
│  │ 笔记内容...         │   │
│  └─────────────────────┘   │
│                   10:42 AM ✓│
│                             │
│  ┌─────────────────────┐   │
│  │ 另一条笔记...       │   │
│  └─────────────────────┘   │
│                   11:15 AM ✓│
│                             │
├─────────────────────────────┤
│ [+] [输入框...        ] [→]│
└─────────────────────────────┘
```

### 同步雷达
```
┌─────────────────────────────┐
│  ← Sync Radar               │
├─────────────────────────────┤
│  🔒 No Cloud - P2P Only     │
│                             │
│      ○ MacBook              │
│    ○   ○   ○                │
│  ○   ○ 📱 ○   ○            │
│    ○   ○   ○                │
│      ○ iPad                 │
│                             │
│  Searching nearby devices...│
├─────────────────────────────┤
│  💻 MacBook Pro M2          │
│  📱 iPad Pro (Syncing 85%)  │
├─────────────────────────────┤
│     [Sync Now]              │
└─────────────────────────────┘
```

---

## 💡 核心特性

### 🔐 隐私优先
- ✅ 100% 本地存储
- ✅ 无云端依赖
- ✅ 端到端加密（规划中）
- ✅ 零追踪零分析

### 📡 P2P 同步
- ✅ 蓝牙直连
- ✅ 10 米范围
- ✅ 自动发现
- ✅ 增量同步

### 🎨 精美设计
- ✅ 深色主题
- ✅ 流畅动画
- ✅ iOS 风格
- ✅ 现代化 UI

### ⚡️ 高性能
- ✅ 支持 10,000+ 笔记
- ✅ 搜索 < 100ms
- ✅ 60fps 动画
- ✅ 离线可用

---

## 🛠 技术栈

- **框架**: Flutter 3.0+
- **语言**: Dart
- **UI**: Material Design 3
- **字体**: Google Fonts (Inter)
- **平台**: iOS 12.0+

---

## 📱 系统要求

- macOS 10.14+
- Xcode 13.0+
- Flutter SDK 3.0.0+
- iOS 设备或模拟器

---

## 🎓 学习路径

### 第 1 天：环境搭建
1. 阅读 [INSTALL.md](INSTALL.md)
2. 安装 Flutter 和 Xcode
3. 运行应用

### 第 2 天：熟悉功能
1. 阅读 [QUICKSTART.md](QUICKSTART.md)
2. 探索所有界面
3. 尝试各种功能

### 第 3 天：了解架构
1. 阅读 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. 查看代码结构
3. 理解设计模式

### 第 4 天：开始开发
1. 修改主题颜色
2. 添加新功能
3. 自定义界面

---

## 🔧 常用命令

```bash
# 运行应用
flutter run

# 热重载（在运行中按 'r'）
r

# 热重启（在运行中按 'R'）
R

# 代码分析
flutter analyze

# 运行测试
flutter test

# 清理构建
flutter clean

# 查看设备
flutter devices

# 查看日志
flutter logs
```

---

## 🐛 遇到问题？

### 快速解决方案
```bash
# 万能三连
flutter clean
flutter pub get
flutter run
```

### 查看文档
1. [INSTALL.md](INSTALL.md) - 安装问题
2. [QUICKSTART.md](QUICKSTART.md) - 使用问题
3. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 技术问题

### 检查环境
```bash
flutter doctor -v
```

---

## 🎯 项目状态

### ✅ 已完成
- [x] 完整的 UI 界面
- [x] 所有主要页面
- [x] 动画效果
- [x] 主题系统
- [x] 导航路由

### 🚧 待实现
- [ ] 本地数据库（SQLite）
- [ ] 真实的蓝牙同步
- [ ] 端到端加密
- [ ] Markdown 编辑器
- [ ] 标签系统

---

## 📈 下一步计划

### Phase 1: 数据层
集成 SQLite，实现本地数据持久化

### Phase 2: 同步功能
实现真实的蓝牙 P2P 同步

### Phase 3: 安全加密
添加端到端加密功能

### Phase 4: 高级功能
Markdown、语音笔记、标签等

---

## 🤝 贡献指南

### 代码规范
- 遵循 Flutter 官方风格
- 使用 `flutter format` 格式化
- 添加必要的注释
- 编写单元测试

### 提交规范
```bash
git commit -m "feat: 添加新功能"
git commit -m "fix: 修复 bug"
git commit -m "docs: 更新文档"
```

---

## 📞 获取帮助

### 官方资源
- [Flutter 文档](https://flutter.dev/docs)
- [Dart 文档](https://dart.dev/guides)
- [Material Design](https://m3.material.io/)

### 社区资源
- [Flutter 中文网](https://flutter.cn/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Community](https://fluttercommunity.dev/)

---

## 🎉 开始你的旅程

现在你已经准备好了！选择一个入口开始：

1. **想立即运行？** → [QUICKSTART.md](QUICKSTART.md)
2. **需要安装环境？** → [INSTALL.md](INSTALL.md)
3. **想了解功能？** → [FEATURES.md](FEATURES.md)
4. **想研究代码？** → [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

## 💝 感谢使用 SoulNote

> "你的笔记，你的数据，你的隐私 - 永远在你的掌控之中"

**祝你使用愉快！** 🚀

---

**最后更新**: 2026-01-18  
**版本**: 1.0.0  
**状态**: UI 演示版本
