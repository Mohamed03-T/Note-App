import 'package:flutter/material.dart';
import '../../models/page_model.dart';
import 'pages_top_bar.dart';
import '../../models/folder_model.dart';
import 'folders_grid.dart';

class PageFoldersScreen extends StatelessWidget {
  final List<PageModel> pages;
  final int activeIndex;
  final PageModel page;
  final List<FolderModel> folders;
  final ValueChanged<FolderModel> onOpenFolder;
  final VoidCallback onAddFolder;
  final ValueChanged<FolderModel> onRenameRequest;
  final ValueChanged<FolderModel> onDeleteRequest;
  final ValueChanged<int>? onOpenPageByIndex;

  const PageFoldersScreen({
    super.key,
    required this.pages,
    required this.activeIndex,
    required this.page,
    required this.folders,
    required this.onOpenFolder,
    required this.onAddFolder,
    required this.onRenameRequest,
    required this.onDeleteRequest,
    this.onOpenPageByIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageFoldersContent(
        pages: pages,
        activeIndex: activeIndex,
        page: page,
        folders: folders,
        onOpenFolder: onOpenFolder,
        onAddFolder: onAddFolder,
        onRenameRequest: onRenameRequest,
        onDeleteRequest: onDeleteRequest,
        onOpenPageByIndex: onOpenPageByIndex,
      ),
    );
  }
}

class PageFoldersContent extends StatelessWidget {
  final List<PageModel> pages;
  final int activeIndex;
  final PageModel page;
  final List<FolderModel> folders;
  final ValueChanged<FolderModel> onOpenFolder;
  final VoidCallback onAddFolder;
  final ValueChanged<FolderModel> onRenameRequest;
  final ValueChanged<FolderModel> onDeleteRequest;
  final ValueChanged<int>? onOpenPageByIndex;

  const PageFoldersContent({
    super.key,
    required this.pages,
    required this.activeIndex,
    required this.page,
    required this.folders,
    required this.onOpenFolder,
    required this.onAddFolder,
    required this.onRenameRequest,
    required this.onDeleteRequest,
    this.onOpenPageByIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PagesTopBar(pageModels: pages, onOpenAllPages: () {}, onPageSelected: (i) { onOpenPageByIndex?.call(i); }, selectedIndex: activeIndex),
        const SizedBox(height: 8),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: FoldersGrid(folders: folders, onAddFolder: onAddFolder, onOpenFolder: onOpenFolder, onRenameRequest: onRenameRequest, onDeleteRequest: onDeleteRequest))),
      ],
    );
  }
}
