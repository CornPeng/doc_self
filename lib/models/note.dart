enum NoteType {
  chat,
  markdown,
}

class Note {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessagePreview;
  final String? lastMessageType; // 'text', 'image', 'video'
  final NoteType noteType;
  final String? markdownContent; // For markdown notes

  Note({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessagePreview,
    this.lastMessageType,
    this.noteType = NoteType.chat,
    this.markdownContent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messageCount': messageCount,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageType': lastMessageType,
      'noteType': noteType.name,
      'markdownContent': markdownContent,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      messageCount: map['messageCount'] ?? 0,
      lastMessagePreview: map['lastMessagePreview'],
      lastMessageType: map['lastMessageType'],
      noteType: map['noteType'] != null 
          ? NoteType.values.firstWhere(
              (e) => e.name == map['noteType'],
              orElse: () => NoteType.chat,
            )
          : NoteType.chat,
      markdownContent: map['markdownContent'],
    );
  }

  // JSON serialization (same as toMap/fromMap)
  Map<String, dynamic> toJson() => toMap();
  
  factory Note.fromJson(Map<String, dynamic> json) => Note.fromMap(json);

  Note copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessagePreview,
    String? lastMessageType,
    NoteType? noteType,
    String? markdownContent,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      noteType: noteType ?? this.noteType,
      markdownContent: markdownContent ?? this.markdownContent,
    );
  }
}
