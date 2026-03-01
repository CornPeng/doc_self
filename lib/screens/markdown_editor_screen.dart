import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soul_note/models/note.dart';
import 'package:soul_note/services/database_service.dart';
import 'package:soul_note/l10n/app_localizations.dart';

class MarkdownEditorScreen extends StatefulWidget {
  final Note note;

  const MarkdownEditorScreen({super.key, required this.note});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService.instance;
  late TextEditingController _contentController;
  late TabController _tabController;
  late FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.markdownContent ?? '');
    _tabController = TabController(length: 2, vsync: this);
    _focusNode = FocusNode();
    
    // 自动保存监听器，使用防抖机制
    _contentController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _saveContent();
      });
    });
    
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _contentController.dispose();
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    final firstLine = _contentController.text.split('\n').first;
    final preview = firstLine.length > 50 ? firstLine.substring(0, 50) : firstLine;
    
    final updatedNote = widget.note.copyWith(
      markdownContent: _contentController.text,
      updatedAt: DateTime.now(),
      lastMessagePreview: preview,
    );
    await _db.updateNote(updatedNote);
  }

  Future<void> _exportMarkdown() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${widget.note.title.replaceAll(' ', '_')}.md';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(_contentController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.exportSuccess}: $fileName',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export error: $e',
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

  Future<void> _importMarkdown() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        setState(() {
          _contentController.text = content;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '导入成功',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import error: $e',
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

  Future<void> _showDeleteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteNote,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.deleteNoteConfirm(widget.note.title),
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (result == true) {
      await _db.deleteNote(widget.note.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _showEditTitleDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: widget.note.title);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.editNoteTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.enterNoteTitle,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.note.title) {
      final updatedNote = widget.note.copyWith(title: result);
      await _db.updateNote(updatedNote);
      setState(() {});
    }
  }

  void _insertMarkdown(String syntax, {int cursorOffset = 0}) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      syntax,
    );
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + syntax.length + cursorOffset,
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.note.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 24),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditTitleDialog();
                  break;
                case 'import':
                  _importMarkdown();
                  break;
                case 'export':
                  _exportMarkdown();
                  break;
                case 'delete':
                  _showDeleteDialog();
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
                    Text(l10n.editNote, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.importMarkdown, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.exportMarkdown, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.deleteNote, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 左侧：预览
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 0
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.preview,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _tabController.index == 0
                              ? const Color(0xFF3B82F6)
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                // 右侧：编辑
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 1
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.edit,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _tabController.index == 1
                              ? const Color(0xFF3B82F6)
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content：左预览，右编辑
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreview(),
                _buildEditor(),
              ],
            ),
          ),
          // Toolbar（仅在编辑页签显示）
          if (_tabController.index == 1) _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: TextField(
          controller: _contentController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'monospace',
            height: 1.6,
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.markdownEditorHint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontFamily: 'monospace',
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF0F172A),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: SingleChildScrollView(
          child: Markdown(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            data: _contentController.text.isEmpty
                ? AppLocalizations.of(context)!.previewEmptyHint
                : _contentController.text,
            styleSheet: MarkdownStyleSheet(
              blockSpacing: 8,
              listIndent: 24,
              blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              codeblockPadding: const EdgeInsets.all(8),
              p: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.6,
              ),
              h1: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 26,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              h2: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              h3: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 19,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              h4: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              h5: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              h6: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              blockquote: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                color: const Color(0xFF93C5FD),
                backgroundColor: Colors.white.withOpacity(0.08),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              listBullet: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
              a: const TextStyle(
                color: Color(0xFF93C5FD),
                decoration: TextDecoration.underline,
              ),
              strong: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontWeight: FontWeight.w600,
              ),
              em: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolbarButton('H1', () {
            _insertMarkdown('# ', cursorOffset: 0);
          }),
          _buildToolbarButton('B', () {
            _insertMarkdown('****', cursorOffset: -2);
          }),
          _buildToolbarButton('I', () {
            _insertMarkdown('**', cursorOffset: -1);
          }),
          _buildToolbarIconButton(Icons.link, () {
            _insertMarkdown('[](url)', cursorOffset: -5);
          }),
          _buildToolbarIconButton(Icons.format_list_bulleted, () {
            _insertMarkdown('- ', cursorOffset: 0);
          }),
          _buildToolbarIconButton(Icons.image, () {
            _insertMarkdown('![](url)', cursorOffset: -5);
          }),
          _buildToolbarIconButton(Icons.code, () {
            _insertMarkdown('``', cursorOffset: -1);
          }),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: color ?? Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}
