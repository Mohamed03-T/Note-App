import 'package:flutter/material.dart';
import 'pages_top_bar.dart';
import 'folders_grid.dart';
import '../../models/folder_model.dart';
import '../../models/page_model.dart';
import 'all_pages_screen.dart';
import 'page_folders_screen.dart';
import '../../repositories/notes_repository.dart';
import 'folder_notes_screen.dart';

class NotesHome extends StatefulWidget {
  const NotesHome({super.key});

  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  final NotesRepository _repo = NotesRepository();
  late List<FolderModel> _folders;

  @override
  void initState() {
    super.initState();
    _folders = _repo.getDefaultFolders();
    final names = ['Study', 'Ideas', 'Notes', 'Archive', 'Personal', 'Drafts'];
    _pages = names.map((t) {
      final folders = _repo.getFoldersForPage(t);
      return PageModel(id: t, title: t, folderCount: folders.length);
    }).toList();
  }

  late List<PageModel> _pages;
  int? _selectedPageIndex;

  void _addFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create folder'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Folder name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                final newFolder = FolderModel(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, lastModified: DateTime.now(), notesCount: 0);
                setState(() => _folders = [newFolder, ..._folders]);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openFolder(FolderModel folder) {
    final notes = _repo.getNotesForFolder(folder.id);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => FolderNotesScreen(folder: folder, notes: notes)));
  }

  void _requestRenameFolder(FolderModel folder) {
    final controller = TextEditingController(text: folder.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename folder'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Folder name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  final idx = _folders.indexWhere((f) => f.id == folder.id);
                  if (idx != -1) {
                    _folders[idx] = FolderModel(id: folder.id, title: name, lastModified: DateTime.now(), notesCount: folder.notesCount);
                  }
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _requestDeleteFolder(FolderModel folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder'),
        content: Text('Are you sure you want to delete "${folder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _folders.removeWhere((f) => f.id == folder.id));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${folder.title}"'), action: SnackBarAction(label: 'Undo', onPressed: () { setState(() => _folders.insert(0, folder)); })));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAllPages() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AllPagesScreen(pages: _pages, onChanged: (p) { setState(() => _pages = p); })));
  }



  void _openPageByIndex(int index) {
    if (index < 0 || index >= _pages.length) return;
    final page = _pages[index];
  final repo = NotesRepository();
  final folders = repo.getFoldersForPage(page.title);
  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PageFoldersScreen(pages: _pages, activeIndex: index, page: page, folders: folders, onOpenFolder: (f) => _openFolder(f), onAddFolder: _addFolderDialog, onRenameRequest: _requestRenameFolder, onDeleteRequest: _requestDeleteFolder)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black), title: const Text('Notes', style: TextStyle(color: Colors.black)),),
      body: Column(
        children: [
          PagesTopBar(pageModels: _pages, onOpenAllPages: _openAllPages, onPageSelected: (i) { setState(() => _selectedPageIndex = i); }, selectedIndex: _selectedPageIndex),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _selectedPageIndex == null
                  ? FoldersGrid(folders: _folders, onAddFolder: _addFolderDialog, onOpenFolder: _openFolder, onRenameRequest: _requestRenameFolder, onDeleteRequest: _requestDeleteFolder)
                  : PageFoldersContent(pages: _pages, activeIndex: _selectedPageIndex!, page: _pages[_selectedPageIndex!], folders: NotesRepository().getFoldersForPage(_pages[_selectedPageIndex!].title), onOpenFolder: _openFolder, onAddFolder: _addFolderDialog, onRenameRequest: _requestRenameFolder, onDeleteRequest: _requestDeleteFolder, onOpenPageByIndex: (i) { setState(() => _selectedPageIndex = i); }),
            ),
          ),
        ],
      ),
      
    );
  }

// selected page index stored in _selectedPageIndex
}
