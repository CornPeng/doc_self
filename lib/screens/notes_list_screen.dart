import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:soul_note/models/note.dart';
import 'package:soul_note/models/message.dart';
import 'package:soul_note/services/database_service.dart';
import 'package:soul_note/screens/note_chat_screen.dart';
import 'package:soul_note/screens/markdown_editor_screen.dart';
import 'package:soul_note/screens/sync_radar_screen.dart';
import 'package:soul_note/l10n/app_localizations.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  List<Message> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredNotes = _notes;
        _searchResults = [];
      });
    } else {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    
    // 搜索笔记标题
    final filteredNotes = _notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
             (note.lastMessagePreview?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
    
    // 搜索消息内容
    final messages = await _db.searchMessages(query);
    
    setState(() {
      _filteredNotes = filteredNotes;
      _searchResults = messages;
    });
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await _db.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
      _isLoading = false;
    });
  }

  Future<void> _showNoteTypeDialog() async {
    final l10n = AppLocalizations.of(context)!;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 80, right: 16, left: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF242426),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernMenuItem(
              icon: Icons.chat_bubble_outline,
              label: l10n.createChatNote,
              backgroundColor: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                _createNewNote(NoteType.chat);
              },
            ),
            _buildMenuDivider(),
            _buildModernMenuItem(
              icon: Icons.article_outlined,
              label: l10n.createMarkdownNote,
              backgroundColor: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _createNewNote(NoteType.markdown);
              },
            ),
            _buildMenuDivider(),
            _buildModernMenuItem(
              icon: Icons.file_upload_outlined,
              label: l10n.importMarkdown,
              backgroundColor: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                _importMarkdownFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: backgroundColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Future<void> _importMarkdownFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final fileName = result.files.single.name.replaceAll(RegExp(r'\.(md|markdown|txt)$'), '');
        
        // 创建新的 Markdown 笔记
        final note = Note(
          id: const Uuid().v4(),
          title: fileName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          noteType: NoteType.markdown,
          markdownContent: content,
          lastMessagePreview: content.split('\n').first.length > 50 
              ? content.split('\n').first.substring(0, 50)
              : content.split('\n').first,
        );
        
        await _db.createNote(note);
        await _loadNotes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '导入成功: $fileName',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 打开导入的笔记
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkdownEditorScreen(note: note),
            ),
          ).then((_) => _loadNotes());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入失败: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _createNewNote(NoteType noteType) async {
    final TextEditingController controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    
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
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final note = Note(
        id: const Uuid().v4(),
        title: result,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        noteType: noteType,
        markdownContent: noteType == NoteType.markdown ? '# $result\n\n' : null,
      );
      await _db.createNote(note);
      await _loadNotes();
      
      // 根据笔记类型进入不同的界面
      if (mounted) {
        if (noteType == NoteType.chat) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteChatScreen(note: note),
            ),
          ).then((_) => _loadNotes());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkdownEditorScreen(note: note),
            ),
          ).then((_) => _loadNotes());
        }
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2632),
        title: Text(l10n.deleteNote, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteNoteConfirm(note.title),
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
      await _db.deleteNote(note.id);
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101922).withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            // 顶部标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF137FEC).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(
                      AppLocalizations.of(context)!.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.appSubtitle,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: const Color(0xFF137FEC),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SyncRadarScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_connected,
                          color: Color(0xFF137FEC),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.p2pActive,
                          style: TextStyle(
                            color: const Color(0xFF137FEC),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 搜索框
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF283039).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF137FEC),
              ),
            )
          : _notes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  color: const Color(0xFF137FEC),
                  child: _isSearching && _searchController.text.isNotEmpty
                      ? _buildSearchResults()
                      : _buildGroupedNotesList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNoteTypeDialog,
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 8,
        child: Transform.rotate(
          angle: 0,
          child: const Icon(
            Icons.add,
            size: 32,
          ),
        ),
      ),
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
              Icons.sticky_note_2_outlined,
              size: 40,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noNotes,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstNote,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedNotesList() {
    final l10n = AppLocalizations.of(context)!;
    
    // 分组笔记
    final chatNotes = _filteredNotes.where((note) => note.noteType == NoteType.chat).toList();
    final markdownNotes = _filteredNotes.where((note) => note.noteType == NoteType.markdown).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Markdown 笔记组
        if (markdownNotes.isNotEmpty) ...[
          _buildSectionHeader(l10n.markdownNotes, markdownNotes.length),
          const SizedBox(height: 8),
          ...markdownNotes.map((note) => _buildNoteCard(note)),
          const SizedBox(height: 24),
        ],
        
        // Chat 笔记组
        if (chatNotes.isNotEmpty) ...[
          _buildSectionHeader(l10n.chatNotes, chatNotes.length),
          const SizedBox(height: 8),
          ...chatNotes.map((note) => _buildNoteCard(note)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF137FEC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _deleteNote(note);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (note.noteType == NoteType.chat) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteChatScreen(note: note),
              ),
            ).then((_) => _loadNotes());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkdownEditorScreen(note: note),
              ),
            ).then((_) => _loadNotes());
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2632),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  note.noteType == NoteType.markdown ? Icons.article : Icons.chat_bubble,
                  color: const Color(0xFF137FEC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (note.lastMessagePreview != null)
                      Text(
                        note.lastMessagePreview!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (note.messageCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${note.messageCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context)!;
    if (_filteredNotes.isEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSearchResults,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 显示匹配的笔记
        if (_filteredNotes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.notesCount(_filteredNotes.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._filteredNotes.map((note) => _buildNoteCard(note)),
        ],
        
        // 显示匹配的消息
        if (_searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              l10n.messagesCount(_searchResults.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._searchResults.map((message) => _buildSearchResultCard(message)),
        ],
      ],
    );
  }

  Widget _buildSearchResultCard(Message message) {
    return FutureBuilder<Note?>(
      future: _db.getNote(message.noteId),
      builder: (context, snapshot) {
        final note = snapshot.data;
        if (note == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteChatScreen(note: note),
              ),
            ).then((_) => _loadNotes());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      message.type == MessageType.image
                          ? Icons.image
                          : message.type == MessageType.video
                              ? Icons.videocam
                              : Icons.chat_bubble_outline,
                      color: const Color(0xFF137FEC),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
