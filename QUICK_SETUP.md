# 🚀 SoulNote 蓝牙同步快速设置

## ⚠️ 重要：设备识别设置

由于技术限制，SoulNote 通过**设备名称**来识别其他运行应用的设备。

### 📱 必须完成的设置

#### iPhone/iPad 设置：
```
1. 打开"设置"
2. 点击"通用"
3. 点击"关于本机"
4. 点击"名称"
5. 在设备名称中添加 "(SoulNote)"

示例：
  之前：Corn的iPhone
  之后：Corn的iPhone (SoulNote)
```

#### Mac 设置：
```
1. 打开"系统偏好设置"（或"系统设置"）
2. 点击"共享"
3. 修改"电脑名称"，添加 "(SoulNote)"

示例：
  之前：MacBook Pro
  之后：MacBook Pro (SoulNote)
```

## ✅ 设置完成后

### 1. 启动应用

**使用启动脚本（推荐）：**
```bash
cd /Users/corn/project/own/doc_self2
./start_both.sh
```

**或手动启动：**

Mac:
```bash
flutter run -d macos
```

iPhone:
```bash
flutter run -d 00008120-001C31563A10A01E
```

### 2. 测试同步

1. **打开 Sync Radar 页面**
   - 在两个设备上都进入同步页面

2. **确保蓝牙已开启**
   - Mac: 菜单栏 > 蓝牙图标
   - iPhone: 控制中心 > 蓝牙

3. **开始扫描**
   - 点击 "Scan Devices" 按钮
   - 等待 10 秒

4. **查看结果**
   - 如果设置正确，应该看到对方设备
   - 设备名称会带有 📱 标记
   - 例如：`Corn的iPhone (SoulNote) 📱`

## 🔍 验证是否设置成功

### 控制台日志

**成功时：**
```
🔍 开始扫描附近的蓝牙设备...
📱 发现 15 个蓝牙设备
  ✅ 发现 SoulNote 设备: Corn的iPhone (SoulNote) (RSSI: -45)
  ⏭️  跳过非 SoulNote 设备: AirPods Pro (RSSI: -55)
  ⏭️  跳过非 SoulNote 设备: Apple Watch (RSSI: -60)

✅ 发现 1 台 SoulNote 设备
   📱 Corn的iPhone (SoulNote) 📱 (iPhone)
```

**失败时（未修改设备名称）：**
```
🔍 开始扫描附近的蓝牙设备...
📱 发现 15 个蓝牙设备
  ⏭️  跳过非 SoulNote 设备: Corn的iPhone (RSSI: -45)
  ⏭️  跳过非 SoulNote 设备: MacBook Pro (RSSI: -38)

❌ 未发现 SoulNote 设备
💡 提示：
   1. 确保其他设备已安装并运行 SoulNote
   2. 确保蓝牙已开启
   3. 修改设备名称包含 "SoulNote"：
      iOS: 设置 > 通用 > 关于本机 > 名称
      macOS: 系统偏好设置 > 共享 > 电脑名称
   例如：Corn的iPhone → Corn的iPhone (SoulNote)
```

## 🎯 为什么需要修改设备名称？

Flutter 的蓝牙库有技术限制：
- ❌ 无法让应用主动广播蓝牙服务
- ❌ 无法在蓝牙广播中添加自定义数据
- ✅ 只能读取设备的蓝牙名称

因此，我们使用设备名称作为识别标识。

## 📋 检查清单

在测试同步前，确保：

### Mac 设备：
- [ ] 已安装并运行 SoulNote
- [ ] 蓝牙已开启
- [ ] 设备名称包含 "(SoulNote)"
- [ ] 在 Sync Radar 页面

### iPhone 设备：
- [ ] 已安装并运行 SoulNote  
- [ ] 蓝牙已开启
- [ ] 设备名称包含 "(SoulNote)"
- [ ] 在 Sync Radar 页面
- [ ] 设备已解锁

### 环境：
- [ ] 两个设备距离 < 10米
- [ ] 没有太多蓝牙干扰

## 🔧 故障排除

### 问题：仍然搜索不到对方

1. **再次确认设备名称**
   ```
   必须包含 "SoulNote" （区分大小写）
   推荐格式：设备名 (SoulNote)
   ```

2. **重启蓝牙**
   ```
   Mac: 关闭并重新打开蓝牙
   iPhone: 关闭并重新打开蓝牙
   ```

3. **重启应用**
   ```
   在两个设备上都按 'R' 键热重启
   或退出重新运行
   ```

4. **查看控制台日志**
   ```
   查找 "✅ 发现 SoulNote 设备" 消息
   如果只看到 "⏭️ 跳过" 说明名称不匹配
   ```

## 💡 提示

- 设备名称可以是任何包含 "SoulNote" 的格式
- 例如：
  - ✅ `Corn的iPhone (SoulNote)`
  - ✅ `SoulNote - iPhone`
  - ✅ `iPhone-SoulNote`
  - ✅ `My SoulNote Device`
  
- 修改名称后不需要重启设备，但需要：
  1. 关闭并重新打开蓝牙
  2. 重启 SoulNote 应用

## 🎉 设置完成

完成上述步骤后，你就可以：
- 📱 在设备间同步笔记
- 🔄 实时查看同步进度
- 📊 查看同步历史
- 🔐 享受端到端加密的本地同步

祝使用愉快！✨
