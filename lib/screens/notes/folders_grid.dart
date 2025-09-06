import 'package:flutter/material.dart';
import 'folder_card.dart';
import '../../models/folder_model.dart';

class FoldersGrid extends StatelessWidget {
  final List<FolderModel> folders;
  final VoidCallback onAddFolder;
  final ValueChanged<FolderModel> onOpenFolder;
  final ValueChanged<FolderModel> onRenameRequest;
  final ValueChanged<FolderModel> onDeleteRequest;

  const FoldersGrid({super.key, required this.folders, required this.onAddFolder, required this.onOpenFolder, required this.onRenameRequest, required this.onDeleteRequest});

  @override
  Widget build(BuildContext context) {
    final items = [...folders, null];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      int crossAxisCount;
      double childAspect = 1.0;

      // responsive breakpoints (you can tune these values)
      // Make 2 columns the default for most device widths.
      if (width < 360) {
        crossAxisCount = 1; // very small screens
        childAspect = 1.2;
      } else if (width < 1000) {
        crossAxisCount = 2; // default for phones and small tablets
        childAspect = 1.05;
      } else if (width < 1400) {
        crossAxisCount = 3; // larger tablets / small desktop
        childAspect = 1.0;
      } else {
        crossAxisCount = 4; // wide screens
        childAspect = 1.0;
      }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspect,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final f = items[i];
          if (f == null) return AddFolderCard(onTap: onAddFolder);
          return FolderCard(folder: f, onTap: () => onOpenFolder(f), onRenameRequest: onRenameRequest, onDeleteRequest: onDeleteRequest);
        },
      );
    });
  }
}

class AddFolderCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddFolderCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1D5DB), width: 2),),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [ Icon(Icons.add_box_outlined, size: 40, color: Color(0xFF9CA3AF)), SizedBox(height: 8), Text('New folder', style: TextStyle(color: Color(0xFF9CA3AF))), ],),),
      ),
    );
  }
}
