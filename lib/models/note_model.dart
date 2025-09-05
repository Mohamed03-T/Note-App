enum AttachmentType { image, audio, other }

class NoteModel {
  final String id;
  final String folderId;
  final String title;
  final String content;
  final List<String> attachments;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    this.attachments = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
