# SoulNote 安装指南

## 🎯 系统要求

### 必需
- **macOS** 10.14 或更高版本
- **Xcode** 13.0 或更高版本
- **Flutter SDK** 3.0.0 或更高版本
- **iOS 设备/模拟器** iOS 12.0+

### 可选
- **CocoaPods** (用于 iOS 依赖管理)
- **VS Code** 或 **Android Studio** (推荐的 IDE)

---

## 📥 安装 Flutter

### 方法 1: 使用官方安装包

1. 访问 [Flutter 官网](https://flutter.dev/docs/get-started/install/macos)
2. 下载 Flutter SDK
3. 解压到合适的位置：
```bash
cd ~/development
unzip ~/Downloads/flutter_macos_*.zip
```

4. 添加到 PATH：
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

5. 验证安装：
```bash
flutter doctor
```

### 方法 2: 使用 Homebrew (推荐)

```bash
# 安装 Homebrew (如果还没有)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Flutter
brew install --cask flutter

# 验证安装
flutter doctor
```

---

## 🔧 配置 iOS 开发环境

### 1. 安装 Xcode

从 Mac App Store 安装 Xcode：
```bash
# 或使用命令行
xcode-select --install
```

### 2. 配置 Xcode

```bash
# 接受许可协议
sudo xcodebuild -license accept

# 安装 Xcode 命令行工具
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 3. 安装 CocoaPods

```bash
sudo gem install cocoapods
```

### 4. 验证配置

```bash
flutter doctor
```

应该看到类似输出：
```
✓ Flutter (Channel stable, 3.x.x)
✓ Xcode - develop for iOS
✓ iOS toolchain
```

---

## 📱 设置 iOS 模拟器

### 启动模拟器

```bash
# 列出可用模拟器
xcrun simctl list devices

# 启动默认模拟器
open -a Simulator

# 或启动特定模拟器
xcrun simctl boot "iPhone 15 Pro"
```

### 推荐的模拟器
- iPhone 15 Pro (iOS 17)
- iPhone 14 Pro (iOS 16)
- iPhone SE (第三代)

---

## 🚀 安装 SoulNote

### 1. 克隆/下载项目

项目已在：
```bash
cd /Users/corn/project/own/doc_self2
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 验证项目

```bash
flutter analyze
```

### 4. 运行应用

#### 方法 A: 使用快速启动脚本
```bash
./run.sh
```

#### 方法 B: 直接使用 Flutter 命令
```bash
# 启动模拟器
open -a Simulator

# 运行应用
flutter run
```

#### 方法 C: 使用 IDE

**VS Code:**
1. 打开项目文件夹
2. 按 F5 或点击 "Run and Debug"
3. 选择 "Dart & Flutter"

**Android Studio:**
1. File → Open → 选择项目文件夹
2. 等待索引完成
3. 点击绿色运行按钮

---

## 📱 在真实设备上运行

### 1. 连接 iPhone

1. 使用 USB 线连接 iPhone 到 Mac
2. 在 iPhone 上点击"信任此电脑"
3. 输入设备密码

### 2. 配置签名

```bash
# 在 Xcode 中打开项目
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择 Runner 项目
2. 选择 Signing & Capabilities
3. 选择你的 Team
4. 勾选 "Automatically manage signing"

### 3. 运行到设备

```bash
# 列出设备
flutter devices

# 运行到指定设备
flutter run -d <device-id>
```

### 4. 信任开发者

首次运行时，在 iPhone 上：
1. 设置 → 通用 → VPN与设备管理
2. 找到你的开发者证书
3. 点击"信任"

---

## 🔍 故障排查

### 问题 1: Flutter doctor 显示错误

**解决方案:**
```bash
# 更新 Flutter
flutter upgrade

# 清理并重新安装
flutter clean
flutter pub get
```

### 问题 2: Xcode 构建失败

**解决方案:**
```bash
# 清理 iOS 构建
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# 重新构建
flutter clean
flutter run
```

### 问题 3: 模拟器无法启动

**解决方案:**
```bash
# 重置模拟器
xcrun simctl erase all

# 或在 Xcode 中
# Xcode → Window → Devices and Simulators
# 右键模拟器 → Delete
```

### 问题 4: 依赖安装失败

**解决方案:**
```bash
# 清理缓存
flutter pub cache repair

# 重新获取依赖
flutter pub get
```

### 问题 5: 签名错误

**解决方案:**
1. 确保有 Apple Developer 账号（免费账号也可以）
2. 在 Xcode 中登录账号
3. 选择正确的 Team
4. 修改 Bundle Identifier 为唯一值

---

## 📊 验证安装

运行以下命令验证一切正常：

```bash
# 1. 检查 Flutter 环境
flutter doctor -v

# 2. 分析代码
flutter analyze

# 3. 运行测试
flutter test

# 4. 构建应用
flutter build ios --debug
```

所有命令都应该成功完成。

---

## 🎓 下一步

安装完成后：

1. 阅读 [QUICKSTART.md](QUICKSTART.md) - 快速入门
2. 查看 [FEATURES.md](FEATURES.md) - 功能详解
3. 参考 [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 项目架构

---

## 💡 开发工具推荐

### VS Code 插件
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

### Xcode 工具
- Instruments (性能分析)
- Network Link Conditioner (网络测试)
- Simulator (设备模拟)

### 命令行工具
```bash
# Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 代码格式化
flutter format .

# 代码生成
flutter pub run build_runner build
```

---

## 🆘 获取帮助

如果遇到问题：

1. **查看文档**
   - README.md
   - QUICKSTART.md
   - 本文件

2. **Flutter 官方资源**
   - [Flutter 文档](https://flutter.dev/docs)
   - [Flutter 社区](https://flutter.dev/community)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

3. **检查日志**
```bash
flutter logs
```

4. **清理重试**
```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ 安装检查清单

- [ ] Flutter SDK 已安装
- [ ] Xcode 已安装并配置
- [ ] iOS 模拟器可用
- [ ] 项目依赖已安装
- [ ] 代码分析无错误
- [ ] 应用可以运行
- [ ] 热重载正常工作

全部完成后，你就可以开始开发了！🎉

---

**提示**: 保持 Flutter 和 Xcode 更新到最新版本，以获得最佳体验。

```bash
# 更新 Flutter
flutter upgrade

# 更新依赖
flutter pub upgrade
```
