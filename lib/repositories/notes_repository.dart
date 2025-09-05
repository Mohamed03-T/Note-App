import '../models/folder_model.dart';
import '../models/note_model.dart';

class NotesRepository {
  List<FolderModel> getDefaultFolders() {
    final now = DateTime.now();
    return [
      FolderModel(id: 'f1', title: 'Lectures', lastModified: now.subtract(const Duration(days: 1)), notesCount: 12),
      FolderModel(id: 'f2', title: 'Homework', lastModified: now.subtract(const Duration(days: 3)), notesCount: 4),
      FolderModel(id: 'f3', title: 'Summaries', lastModified: now.subtract(const Duration(days: 5)), notesCount: 7),
      FolderModel(id: 'f4', title: 'Ideas', lastModified: now.subtract(const Duration(days: 10)), notesCount: 2),
    ];
  }

  // Returns a small set of mock notes for a given folder id.
  List<NoteModel> getNotesForFolder(String folderId) {
    final now = DateTime.now();
    if (folderId == 'f1') {
      return [
        NoteModel(id: 'n1', folderId: folderId, title: 'Calc 1', content: 'Remember to review integration by parts.', createdAt: now.subtract(const Duration(days: 1, hours: 2))),
        NoteModel(id: 'n2', folderId: folderId, title: 'Calc 2', content: 'Study theorem on limits.', createdAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 5))),
        NoteModel(id: 'n3', folderId: folderId, title: 'Lecture notes', content: 'Professor showed example on series.', createdAt: now.subtract(const Duration(days: 2, hours: 3))),
      ];
    } else if (folderId == 'f2') {
      return [
        NoteModel(id: 'n4', folderId: folderId, title: 'HW1', content: 'Question 3 needs rework.', createdAt: now.subtract(const Duration(hours: 4))),
        NoteModel(id: 'n5', folderId: folderId, title: 'HW2', content: 'Start early on the group task.', createdAt: now.subtract(const Duration(hours: 2, minutes: 30))),
      ];
    } else if (folderId == 'f3') {
      return [
        NoteModel(id: 'n6', folderId: folderId, title: 'Summary A', content: 'Key points: state, props, widget lifecycle.', createdAt: now.subtract(const Duration(days: 3))),
      ];
    }

    // default small sample
    return [
      NoteModel(id: 'n7', folderId: folderId, title: 'Idea', content: 'Draft note...', createdAt: now),
    ];
  }
}
