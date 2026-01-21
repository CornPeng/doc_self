class Message {
  final String id;
  final String noteId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isSynced;
  final String? mediaPath; // 本地文件路径或网络 URL

  Message({
    required this.id,
    required this.noteId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isSynced = false,
    this.mediaPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
      'mediaPath': mediaPath,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      noteId: map['noteId'],
      content: map['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isSynced: map['isSynced'] == 1,
      mediaPath: map['mediaPath'],
    );
  }

  Message copyWith({
    String? id,
    String? noteId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    bool? isSynced,
    String? mediaPath,
  }) {
    return Message(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      mediaPath: mediaPath ?? this.mediaPath,
    );
  }
}

enum MessageType {
  text,
  image,
  video,
}
