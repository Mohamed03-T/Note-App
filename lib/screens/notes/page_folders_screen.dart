import 'package:flutter/material.dart';
import '../../models/page_model.dart';
import '../../models/folder_model.dart';
import 'folders_grid.dart';

class PageFoldersScreen extends StatelessWidget {
  final PageModel page;
  final List<FolderModel> folders;
  final ValueChanged<FolderModel> onOpenFolder;
  final VoidCallback onAddFolder;
  final ValueChanged<FolderModel> onRenameRequest;
  final ValueChanged<FolderModel> onDeleteRequest;

  const PageFoldersScreen({super.key, required this.page, required this.folders, required this.onOpenFolder, required this.onAddFolder, required this.onRenameRequest, required this.onDeleteRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(page.title), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      backgroundColor: Colors.white,
      body: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: FoldersGrid(folders: folders, onAddFolder: onAddFolder, onOpenFolder: onOpenFolder, onRenameRequest: onRenameRequest, onDeleteRequest: onDeleteRequest)),
    );
  }
}
