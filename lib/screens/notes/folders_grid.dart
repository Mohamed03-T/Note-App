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

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final f = items[i];
        if (f == null) {
          return AddFolderCard(onTap: onAddFolder);
        }
        return FolderCard(folder: f, onTap: () => onOpenFolder(f), onRenameRequest: onRenameRequest, onDeleteRequest: onDeleteRequest,);
      },
    );
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
