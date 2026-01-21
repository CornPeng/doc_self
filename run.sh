#!/bin/bash

# SoulNote 快速启动脚本

echo "🚀 SoulNote - 本地优先笔记应用"
echo "================================"
echo ""

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter 未安装，请先安装 Flutter SDK"
    echo "访问: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter 已安装"
echo ""

# 检查依赖
echo "📦 检查依赖..."
if [ ! -d ".dart_tool" ]; then
    echo "首次运行，正在安装依赖..."
    flutter pub get
else
    echo "✅ 依赖已安装"
fi
echo ""

# 列出可用设备
echo "📱 可用设备列表:"
flutter devices
echo ""

# 询问用户选择
echo "请选择运行方式:"
echo "1) 自动选择设备运行"
echo "2) iOS 模拟器"
echo "3) 查看帮助"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🏃 正在启动应用..."
        flutter run
        ;;
    2)
        echo ""
        echo "📱 正在启动 iOS 模拟器..."
        open -a Simulator
        sleep 3
        echo "🏃 正在启动应用..."
        flutter run
        ;;
    3)
        echo ""
        echo "📖 帮助信息"
        echo "==========="
        echo ""
        echo "运行命令:"
        echo "  flutter run              - 自动选择设备运行"
        echo "  flutter run -d <device>  - 指定设备运行"
        echo ""
        echo "开发命令:"
        echo "  flutter analyze          - 代码分析"
        echo "  flutter test             - 运行测试"
        echo "  flutter clean            - 清理构建"
        echo ""
        echo "热重载:"
        echo "  按 'r' - 热重载"
        echo "  按 'R' - 热重启"
        echo "  按 'q' - 退出"
        echo ""
        echo "更多信息请查看:"
        echo "  - README.md - 项目说明"
        echo "  - QUICKSTART.md - 快速入门"
        echo "  - FEATURES.md - 功能详解"
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac
