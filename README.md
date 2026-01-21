# SoulNote - 本地优先笔记应用

一个基于 Flutter 构建的本地优先、P2P 同步的笔记应用，专为 iOS 平台设计。

## 特性

- 🔒 **完全本地化** - 数据永不离开你的本地网络
- 📡 **P2P 蓝牙同步** - 设备间直接同步，无需云端
- 🌙 **精美深色主题** - 现代化的 UI 设计
- 🔐 **端到端加密** - 隐私优先的设计理念
- 📱 **iOS 原生体验** - 流畅的界面和交互

## 主要界面

### 1. 笔记流（Note Stream）
- 类似聊天的笔记界面
- 支持文本和图片
- 实时同步状态显示

### 2. 设备同步雷达（Sync Radar）
- 可视化的设备发现界面
- 实时显示附近设备
- 同步进度监控

### 3. 搜索（Search）
- 本地加密搜索
- 标签高亮显示
- 快速过滤结果

### 4. 设置（Settings）
- 设备身份管理
- 存储空间管理
- 自动同步偏好设置

## 安装和运行

### 前置要求
- Flutter SDK (>=3.0.0)
- Xcode (用于 iOS 开发)
- iOS 设备或模拟器

### 安装步骤

1. 克隆项目
```bash
cd doc_self2
```

2. 获取依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── theme/
│   └── app_theme.dart       # 主题配置
└── screens/
    ├── main_navigation.dart  # 主导航
    ├── note_stream_screen.dart    # 笔记流界面
    ├── sync_radar_screen.dart     # 同步雷达界面
    ├── search_screen.dart         # 搜索界面
    └── settings_screen.dart       # 设置界面
```

## 技术栈

- **Flutter** - UI 框架
- **Material Design 3** - 设计系统
- **Google Fonts** - Inter 字体
- **自定义动画** - 雷达扫描、脉冲效果

## 设计理念

SoulNote 遵循"本地优先"（Local-First）的设计理念：

- ✅ 无需网络连接即可使用
- ✅ 数据完全由用户控制
- ✅ 通过 P2P 技术实现设备间同步
- ✅ 零服务器依赖
- ✅ 隐私至上

## 颜色主题

- **主色** - #137FEC (蓝色)
- **背景色** - #101922 (深灰)
- **卡片色** - #1C2632 (灰蓝)
- **边框色** - #283039 (中灰)

## 开发说明

本应用目前为 UI 演示版本，主要功能包括：

- ✅ 完整的 UI 界面
- ✅ 页面导航和路由
- ✅ 动画效果
- ⚠️ P2P 同步功能需要集成蓝牙库
- ⚠️ 本地数据库需要集成存储解决方案

## 未来规划

- [ ] 集成 SQLite 实现本地数据持久化
- [ ] 实现真实的蓝牙 P2P 同步
- [ ] 添加端到端加密
- [ ] 支持 Markdown 编辑
- [ ] 添加语音笔记功能
- [ ] 实现标签系统

## 许可证

MIT License

## 作者

SoulNote Development Team
