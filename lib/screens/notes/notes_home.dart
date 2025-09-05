import 'package:flutter/material.dart';
import 'pages_top_bar.dart';
import 'folders_grid.dart';
import '../../models/folder_model.dart';
import '../../repositories/notes_repository.dart';
import '../../widgets/unified_bottom_bar.dart';
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
  }

  final List<String> _pages = ['Study', 'Ideas', 'Notes', 'Archive', 'Personal', 'Drafts'];

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

  void _openAllPages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.95,
        child: Scaffold(
          appBar: AppBar(title: const Text('Pages'), actions: [ TextButton.icon(onPressed: () { Navigator.of(ctx).pop(); _createNewPageDialog(); }, icon: const Icon(Icons.add, color: Colors.white), label: const Text('New Page', style: TextStyle(color: Colors.white))) ]),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: _pages.length,
              itemBuilder: (c, i) => Card(child: InkWell(onTap: () { Navigator.of(ctx).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open page: ${_pages[i]}'))); }, child: Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [ const Icon(Icons.description), const SizedBox(width: 12), Expanded(child: Text(_pages[i], style: const TextStyle(fontWeight: FontWeight.w600))), ])))),
            ),
          ),
        ),
      ),
    );
  }

  void _createNewPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create page'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Page name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { final title = controller.text.trim(); if (title.isNotEmpty) { setState(() => _pages.insert(0, title)); } Navigator.of(ctx).pop(); }, child: const Text('Create')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black), title: const Text('Notes', style: TextStyle(color: Colors.black)),),
      body: Column(children: [ PagesTopBar(pages: _pages, onOpenAllPages: _openAllPages), const SizedBox(height: 8), Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: FoldersGrid(folders: _folders, onAddFolder: _addFolderDialog, onOpenFolder: _openFolder, onRenameRequest: _requestRenameFolder, onDeleteRequest: _requestDeleteFolder, ),),), ],),
      bottomNavigationBar: UnifiedBottomBar(currentIndex: 2, onTap: (i) { switch (i) { case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break; case 1: Navigator.pushNamed(context, '/tasks'); break; case 2: break; case 3: Navigator.pushNamed(context, '/tasks'); break; case 4: Navigator.pushNamed(context, '/settings'); break; } },),
    );
  }
}
