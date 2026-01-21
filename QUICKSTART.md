# SoulNote 快速入门指南

## 🚀 立即运行

### 方法 1: 使用 iOS 模拟器

```bash
# 1. 启动 iOS 模拟器
open -a Simulator

# 2. 在项目目录运行
cd /Users/corn/project/own/doc_self2
flutter run
```

### 方法 2: 连接真实 iOS 设备

```bash
# 1. 通过 USB 连接你的 iPhone
# 2. 信任设备后运行
flutter run
```

## 📱 应用功能演示

### 主要页面

1. **笔记流界面** (默认页面)
   - 查看所有笔记
   - 支持文本和图片
   - 显示同步状态
   - 点击顶部的 "P2P Active" 查看同步雷达

2. **搜索界面** (底部第二个标签)
   - 搜索本地笔记
   - 标签高亮显示
   - 加密搜索提示

3. **设置界面** (底部第三个标签)
   - 设备身份管理
   - 存储管理
   - 自动同步设置
   - 数据删除

### 特色功能

#### 同步雷达
从主界面点击顶部的蓝色 "P2P Active" 徽章，进入设备同步雷达界面：
- 可视化显示附近设备
- 实时同步状态
- 设备列表

## 🎨 界面特点

- **深色主题** - 护眼的深色设计
- **流畅动画** - 脉冲、旋转等动画效果
- **现代化 UI** - 圆角、模糊、阴影效果
- **Material Design 3** - 遵循最新设计规范

## 🔧 自定义配置

### 修改主题颜色

编辑 `lib/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF137FEC); // 改成你喜欢的颜色
```

### 添加新笔记

在 `lib/screens/note_stream_screen.dart` 的 `_messages` 列表中添加：

```dart
NoteMessage(
  text: '你的笔记内容',
  time: DateTime.now(),
  isSynced: true,
),
```

## 📝 开发说明

### 项目结构

```
lib/
├── main.dart                      # 应用入口
├── theme/
│   └── app_theme.dart            # 主题配置
└── screens/
    ├── main_navigation.dart       # 底部导航
    ├── note_stream_screen.dart    # 笔记流
    ├── sync_radar_screen.dart     # 同步雷达
    ├── search_screen.dart         # 搜索
    └── settings_screen.dart       # 设置
```

### 热重载

开发时修改代码后，在终端按 `r` 进行热重载，按 `R` 进行热重启。

## 🎯 下一步

当前版本是 UI 演示版本。要实现完整功能，建议：

1. **数据持久化** - 集成 SQLite (sqflite 包)
2. **蓝牙同步** - 使用 flutter_blue_plus 包
3. **加密** - 使用 encrypt 包
4. **状态管理** - 使用 Provider 或 Riverpod

## 💡 提示

- 图片使用了网络链接，需要网络连接才能加载
- 所有数据目前都是静态演示数据
- 同步功能是模拟的，需要集成真实的蓝牙库

## ❓ 问题排查

### 无法运行

```bash
# 检查 Flutter 环境
flutter doctor

# 清理并重新获取依赖
flutter clean
flutter pub get
```

### iOS 签名问题

在 Xcode 中打开项目：
```bash
open ios/Runner.xcworkspace
```

然后在 Xcode 中设置你的开发团队和签名证书。

## 🎉 享受使用

祝你使用愉快！有任何问题随时查看代码注释或 README.md。
