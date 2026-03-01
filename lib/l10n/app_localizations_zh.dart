// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'SoulNote';

  @override
  String get appSubtitle => '本地笔记';

  @override
  String get searchHint => '搜索笔记...';

  @override
  String get notes => '笔记';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get createNote => '创建笔记';

  @override
  String get newNote => '新建笔记';

  @override
  String get enterNoteTitle => '输入笔记标题...';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get delete => '删除';

  @override
  String get deleteNote => '删除笔记';

  @override
  String deleteNoteConfirm(String title) {
    return '确定要删除\"$title\"吗？\\n这将同时删除所有相关消息。';
  }

  @override
  String get noNotes => '还没有笔记';

  @override
  String get createFirstNote => '点击右下角按钮创建第一个笔记';

  @override
  String get p2pActive => 'P2P 活跃';

  @override
  String get messageInput => '输入消息...';

  @override
  String get startRecording => '开始记录想法';

  @override
  String get selectImage => '选择图片';

  @override
  String get selectVideo => '选择视频';

  @override
  String notesCount(int count) {
    return '笔记 ($count)';
  }

  @override
  String messagesCount(int count) {
    return '消息 ($count)';
  }

  @override
  String get noSearchResults => '没有找到匹配的结果';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get image => '图片';

  @override
  String get video => '视频';

  @override
  String get deviceIdentity => '设备身份';

  @override
  String get deviceIdentityDesc => '其他设备可见';

  @override
  String get storageManagement => '存储管理';

  @override
  String storageSize(String size) {
    return '本地数据库：$size';
  }

  @override
  String get autoSync => '自动同步设置';

  @override
  String get autoSyncDesc => '蓝牙自动发现以进行本地同步';

  @override
  String get deleteAllData => '删除所有本地数据';

  @override
  String get privacyMessage => '你的数据永不离开本地网络。无云端，无追踪。';

  @override
  String get syncRadar => '同步雷达';

  @override
  String get noCloud => '无云端 — 仅 P2P 蓝牙';

  @override
  String get searchingDevices => '正在搜索附近的设备...';

  @override
  String get stayClose => '保持在 10 米范围内以获得最佳效果';

  @override
  String get syncNow => '立即同步';

  @override
  String get encryptionMessage => '你的笔记永不离开本地网络。\\n数据端到端加密。';

  @override
  String get language => '语言';

  @override
  String get languageSettings => '语言设置';

  @override
  String get selectLanguage => '选择你偏好的语言';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get deleteAllDataTitle => '删除所有数据？';

  @override
  String get deleteAllDataMessage =>
      '这将永久删除所有本地笔记和设置。此操作无法撤销。\n\n注意：此删除只删除本机缓存，其他设备不受影响，并且可以通过同步恢复。';

  @override
  String get deleteSuccess => '所有数据已删除成功';

  @override
  String get edit => '编辑';

  @override
  String get editNote => '编辑笔记';

  @override
  String get editNoteTitle => '编辑笔记标题';

  @override
  String get save => '保存';

  @override
  String get preview => '预览';

  @override
  String get importMarkdown => '导入 Markdown';

  @override
  String get exportMarkdown => '导出 Markdown';

  @override
  String get exportSuccess => '导出成功';

  @override
  String get chatNotes => '聊天笔记';

  @override
  String get markdownNotes => 'Markdown 笔记';

  @override
  String get createChatNote => '创建聊天笔记';

  @override
  String get createMarkdownNote => '创建 Markdown 笔记';

  @override
  String get bluetoothBinding => '蓝牙绑定';

  @override
  String get bluetoothBindingDesc => '管理已配对的设备以进行 P2P 同步';

  @override
  String get boundDevices => '已绑定设备';

  @override
  String get availableDevices => '可用设备';

  @override
  String get noBoundDevices => '还没有绑定的设备';

  @override
  String get noDevicesFound => '未找到设备\n点击 \"搜索设备\" 开始扫描';

  @override
  String get scanning => '扫描中...';

  @override
  String get searchForDevices => '搜索设备';

  @override
  String get searching => '搜索中...';

  @override
  String get showMyQr => '我的二维码';

  @override
  String get scanQrToPair => '扫码配对';

  @override
  String get enterPairingPassword => '输入配对密码';

  @override
  String linkTo(String name) {
    return '链接到 \"$name\"';
  }

  @override
  String get link => '链接';

  @override
  String get pairingHint => '点击设备以开始配对。确保对方设备处于可发现模式并且已启用蓝牙以进行本地 P2P 同步。';

  @override
  String pairedSuccessfully(String name) {
    return '已成功与 $name 配对';
  }

  @override
  String unboundFrom(String name) {
    return '已与 $name 解绑';
  }

  @override
  String get enterFourDigitPassword => '请输入 4 位数字密码';

  @override
  String get bluetoothSearch => '蓝牙搜索';

  @override
  String get bluetoothSearchDesc => '手动搜索与配对';

  @override
  String get sync => '同步';

  @override
  String get syncDesc => '与附近设备同步';

  @override
  String get shareComingSoon => '分享功能开发中...';

  @override
  String get captureThought => '记录一个想法...';

  @override
  String get markdownEditorHint => '# Markdown 编辑器\n\n开始编写内容...';

  @override
  String get autoSyncRadar => '自动同步雷达';

  @override
  String get syncLogs => '同步日志';

  @override
  String get close => '关闭';

  @override
  String get unlink => '解除';

  @override
  String get invalidQr => '二维码无效';

  @override
  String get qrParseFailed => '二维码解析失败';

  @override
  String sendingPairingRequest(String name) {
    return '正在向 $name 发送配对请求...';
  }

  @override
  String inviteFailed(String error) {
    return '发送邀请失败: $error';
  }

  @override
  String get pairingCodeMismatch => '配对码不匹配，请重新输入';

  @override
  String waitingForConfirm(String name) {
    return '已发送配对码，等待 $name 确认';
  }

  @override
  String get qrPairingVerifying => '收到扫码配对请求，正在验证...';

  @override
  String searchingDevice(String name) {
    return '正在搜索设备: $name...';
  }

  @override
  String get searchTimeout => '搜索超时，请确保对方也在绑定页面并已开始搜索';

  @override
  String connecting(String name) {
    return '正在连接: $name...';
  }

  @override
  String get connectTimeout => '连接超时，请确保对方设备也在配对页面';

  @override
  String connectFailed(String error) {
    return '连接失败: $error';
  }

  @override
  String unboundDevice(String name) {
    return '已解除与 $name 的绑定';
  }

  @override
  String get previewEmptyHint => '预览\n\n在编辑器中输入 Markdown 内容，这里将显示预览效果。';

  @override
  String get justNow => '刚刚';

  @override
  String minAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String hoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String daysAgoShort(int n) {
    return '$n 天前';
  }
}
