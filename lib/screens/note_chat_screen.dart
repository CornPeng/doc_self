import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:soul_note/models/note.dart';
import 'package:soul_note/models/message.dart';
import 'package:soul_note/services/database_service.dart';
import 'package:soul_note/l10n/app_localizations.dart';

class NoteChatScreen extends StatefulWidget {
  final Note note;

  const NoteChatScreen({super.key, required this.note});

  @override
  State<NoteChatScreen> createState() => _NoteChatScreenState();
}

class _NoteChatScreenState extends State<NoteChatScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  /// 本页展示的数据：笔记来自 widget.note，消息来自 DB getMessagesForNote(note.id)
  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    print('loadMessages: ${widget.note.id}');
    final messages = await _db.getMessagesForNote(widget.note.id);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    // 打印当前页面的数据，便于对比是否与 DB/预期一致
    final note = widget.note;
    print('========== [聊天页-当前数据] ==========');
    print('Note: id=${note.id} title="${note.title}" createdAt=${note.createdAt} updatedAt=${note.updatedAt} noteType=${note.noteType} messageCount=${note.messageCount}');
    print('Messages(count=${messages.length}):');
    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      print('  [$i] id=${m.id} content="${m.content}" type=${m.type} createdAt=${m.createdAt} isSynced=${m.isSynced}');
    }
    print('======================================');
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      id: const Uuid().v4(),
      noteId: widget.note.id,
      content: text,
      type: MessageType.text,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    _messageController.clear();
    await _db.createMessage(message);
    await _loadMessages();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // 将图片复制到应用文档目录
        final String savedPath = await _saveMediaFile(image.path, 'images');
        
        final l10n = AppLocalizations.of(context)!;
        final message = Message(
          id: const Uuid().v4(),
          noteId: widget.note.id,
          content: l10n.image,
          type: MessageType.image,
          createdAt: DateTime.now(),
          isSynced: false,
          mediaPath: savedPath,
        );

        await _db.createMessage(message);
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectImage}: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        // 将视频复制到应用文档目录
        final String savedPath = await _saveMediaFile(video.path, 'videos');
        
        final l10n = AppLocalizations.of(context)!;
        final message = Message(
          id: const Uuid().v4(),
          noteId: widget.note.id,
          content: l10n.video,
          type: MessageType.video,
          createdAt: DateTime.now(),
          isSynced: false,
          mediaPath: savedPath,
        );

        await _db.createMessage(message);
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectVideo}: $e')),
        );
      }
    }
  }

  /// 保存媒体文件到应用文档目录
  Future<String> _saveMediaFile(String sourcePath, String subDir) async {
    try {
      // 获取应用文档目录
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // 创建子目录 (images 或 videos)
      final Directory mediaDir = Directory(path.join(appDocDir.path, subDir));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      // 生成新的文件名
      final String fileName = '${const Uuid().v4()}${path.extension(sourcePath)}';
      final String targetPath = path.join(mediaDir.path, fileName);
      
      // 复制文件
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      // 如果保存失败，返回原路径
      return sourcePath;
    }
  }

  void _showMediaPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2632),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF137FEC)),
                title: Text(l10n.selectImage, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF137FEC)),
                title: Text(l10n.selectVideo, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: const Color(0xFF1C2632),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editNoteTitle();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
                case 'share':
                  _shareNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.delete, // 临时使用，稍后添加翻译
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF137FEC),
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C2632),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  DateFormat('yyyy年MM月dd日').format(
                                    widget.note.createdAt,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = _messages[index - 1];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  void _editNoteTitle() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(text: widget.note.title);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2632),
        title: Text(l10n.newNote, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.enterNoteTitle,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF137FEC)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.note.title) {
      final updatedNote = widget.note.copyWith(
        title: result,
        updatedAt: DateTime.now(),
      );
      await _db.updateNote(updatedNote);
      setState(() {}); // 刷新标题
    }
  }

  void _deleteNote() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2632),
        title: Text(l10n.deleteNote, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteNoteConfirm(widget.note.title),
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteNote(widget.note.id);
      if (mounted) {
        Navigator.pop(context); // 返回到笔记列表
      }
    }
  }

  void _shareNote() {
    // TODO: 实现分享功能
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareComingSoon)),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.startRecording,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.messageInput,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isSynced
                  ? const Color(0xFF1C2632)
                  : const Color(0xFF137FEC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: !message.isSynced
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: !message.isSynced
                  ? [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: _buildMessageContent(message),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                message.isSynced ? Icons.done_all : Icons.schedule,
                size: 12,
                color: const Color(0xFF137FEC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: message.isSynced
                ? Colors.white.withOpacity(0.9)
                : Colors.white,
          ),
        );
      case MessageType.image:
        if (message.mediaPath != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(message.mediaPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              if (message.content.isNotEmpty && message.content != '图片')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          );
        }
                return Text('[${AppLocalizations.of(context)!.image}]');
      case MessageType.video:
        if (message.mediaPath != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VideoPlayerWidget(videoPath: message.mediaPath!),
              if (message.content.isNotEmpty && message.content != '视频')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          );
        }
        return Text('[${AppLocalizations.of(context)!.video}]');
    }
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101922).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _showMediaPicker,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2632),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2632),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: l10n.messageInput,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: GestureDetector(
                        onTap: _sendTextMessage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF137FEC),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF137FEC).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerWidget({required this.videoPath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
