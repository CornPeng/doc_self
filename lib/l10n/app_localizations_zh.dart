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
}
