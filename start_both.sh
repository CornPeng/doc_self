#!/bin/bash

# 启动 Mac 和 iPhone 应用的脚本

echo "🚀 启动 SoulNote - Mac 和 iPhone"
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装或不在 PATH 中"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")"

# 停止之前的进程
echo "🛑 停止之前的 Flutter 进程..."
pkill -9 -f "flutter run" 2>/dev/null || true

# 启动 Mac 应用
echo ""
echo "🖥️  启动 Mac 应用..."
flutter run -d macos &
MAC_PID=$!

# 等待 5 秒
sleep 5

# 启动 iPhone 应用
echo ""
echo "📱 启动 iPhone 应用..."
flutter run -d 00008120-001C31563A10A01E &
IPHONE_PID=$!

echo ""
echo "✅ 两个应用正在启动..."
echo "   Mac 进程 ID: $MAC_PID"
echo "   iPhone 进程 ID: $IPHONE_PID"
echo ""
echo "💡 提示："
echo "   - 在任一终端按 'r' 进行热重载"
echo "   - 在任一终端按 'R' 进行热重启"
echo "   - 在任一终端按 'q' 退出应用"
echo ""
echo "🔍 测试蓝牙同步："
echo "   1. 在两个设备上打开 Sync Radar 页面"
echo "   2. 确保蓝牙已开启"
echo "   3. 点击 'Sync Now' 或 'Scan Devices'"
echo "   4. 查看控制台输出的扫描日志"
echo ""

# 等待进程
wait
