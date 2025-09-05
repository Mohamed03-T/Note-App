class FolderModel {
  final String id;
  final String title;
  final DateTime lastModified;
  final int notesCount;

  FolderModel({
    required this.id,
    required this.title,
    required this.lastModified,
    required this.notesCount,
  });

  String get lastModifiedShort {
    final y = lastModified.year;
    final m = lastModified.month.toString().padLeft(2, '0');
    final d = lastModified.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
