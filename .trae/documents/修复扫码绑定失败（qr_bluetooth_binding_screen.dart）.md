## 问题分析
- 两个绑定页面的二维码数据结构不一致：`BluetoothBindingScreen` 使用 `{app:'SoulNote', peerId, peerName, pairingCode}`，而 `QrBluetoothBindingScreen` 使用 `{deviceId, deviceName, pairingCode}`，导致跨页面扫码时被判定为无效（参考 lib/screens/bluetooth_binding_screen.dart:384-413）。
- 扫码后配对码的存储键不统一：当前用设备名称作为键，`SyncService` 内部以 `peerId`（即 displayName）作为主键进行校验（参考 lib/services/sync_service.dart:324-331），需要统一使用 `peerId`/`displayName`。
- 设备发现存在竞争条件：仅在固定延时后检查一次列表，未命中时依赖流式更新，缺少“发现即邀请”的回调和重试策略，可能导致“搜索不到对方”。
- 事件处理与另一页面有差异：`BluetoothBindingScreen` 在 `peerFound` 时尝试基于扫码信息自动邀请（参考 lib/screens/bluetooth_binding_screen.dart:415-425），建议在 QR 页面也做同样处理，以缩短时延。

## 修改方案
1. 统一二维码生成格式（兼容）
   - 在 `QrBluetoothBindingScreen` 生成二维码时，改为包含：`app:'SoulNote'`、`peerId`（用 `SyncService.deviceName` 作为 displayName）、`peerName`（同上）、`pairingCode`、`timestamp`（参考 lib/screens/qr_bluetooth_binding_screen.dart:71-77）。
   - 保留旧字段以兼容旧版（`deviceId/deviceName`），但以新字段为主。

2. 扫码解析时兼容两种负载
   - `_handleQrScanResult` 同时支持解析 `{app, peerId, peerName, pairingCode}` 与 `{deviceId, deviceName, pairingCode}`。
   - 规范化目标标识：`targetPeerId = peerId ?? deviceName`；`targetPeerName = peerName ?? deviceName`。
   - 统一存储配对码：`_syncService.setPendingPairingCode(targetPeerId, pairingCode)`（参考 lib/services/sync_service.dart:524-526）。

3. 加强设备发现与邀请逻辑
   - 扫码后立即 `startScanningForBinding()` 并在 `devicesStream` 命中目标后立刻邀请（现有逻辑保留）。
   - 新增“发现即邀请”路径：在 Multipeer 事件 `peerFound` 命中目标时直接调用 `_multipeer.invitePeer(targetPeerId, pairingCode)`（对齐 lib/screens/bluetooth_binding_screen.dart:415-425 的做法）。
   - 增加重试策略：在 10-15 秒窗口内每 1-2 秒轮询 `_syncService.connectedDevices` 与 `_multipeer.discoveredPeers`，一旦匹配到 `targetPeerId/Name` 就发送邀请。

4. 连接与配对验证的统一
   - 在 `peerStateChanged==connected` 时，如果连接的是目标设备且已持有配对码，延迟 300-500ms 调用 `_sendPairingVerification(peerId, code)`（参考 lib/screens/qr_bluetooth_binding_screen.dart:165-177 与 lib/screens/bluetooth_binding_screen.dart:114-121）。
   - 依赖 `SyncService` 的数据面通道完成校验与“双方加入可信设备”，不重复本地添加（参考 lib/services/sync_service.dart:318-381, 383-411）。

5. 文案与提示优化
   - 当二维码格式不含 `app:'SoulNote'` 或字段不全时，给出明确提示并回退到旧格式解析。
   - 当 10 秒后仍未发现对方时，提醒“请确保对方也在绑定页面并已开始搜索/广播”。

## 具体改动点（文件与位置）
- 生成二维码：`lib/screens/qr_bluetooth_binding_screen.dart:71-77` 改为生成含 `app/peerId/peerName/pairingCode/timestamp` 的 JSON。
- 扫码处理：`lib/screens/qr_bluetooth_binding_screen.dart:357-447` 改为兼容两种结构并统一 `targetPeerId`，用 `setPendingPairingCode(targetPeerId, code)`。
- 设备发现与自动邀请：
  - 在初始化后的事件订阅中增加 `peerFound` 命中目标即邀请（参考现有订阅块 `lib/screens/qr_bluetooth_binding_screen.dart:145-182`）。
  - 增加重试轮询逻辑于 `_handleQrScanResult` 之后（同一文件、同一函数段）。
- 连接成功后的验证：确保仅在目标设备连接且存在 `_qrPairingCode` 时发送 `_sendPairingVerification`（`lib/screens/qr_bluetooth_binding_screen.dart:165-177`）。

## 验证步骤
- 在两台设备上分别打开绑定页面：一台展示二维码（QR 页面），另一台扫码（可以是 QR 页面或 `BluetoothBindingScreen`）。
- 扫码后观察：
  - 10 秒内是否能够发现目标并自动发出邀请；
  - 连接建立后是否收到配对结果提示，双方是否加入“已绑定设备”；
- 交叉测试：
  - 用 `BluetoothBindingScreen` 扫 `QrBluetoothBindingScreen` 的二维码；
  - 用 `QrBluetoothBindingScreen` 扫 `BluetoothBindingScreen` 的二维码（其二维码通过“显示我的二维码”产生，参考 lib/screens/bluetooth_binding_screen.dart:224-315）。

## 影响范围与兼容性
- 仅改动 `qr_bluetooth_binding_screen.dart` 的二维码格式、解析与邀请策略，保持 `SyncService/MultipeerService` 不变。
- 向后兼容旧二维码（保留 deviceName/deviceId 解析），跨页面互通通过统一 `app/peerId/peerName/pairingCode` 实现。

请确认以上方案，确认后我将直接在代码中完成改动并进行本地验证。