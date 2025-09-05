import 'package:flutter/material.dart';
import '../../models/folder_model.dart';

class FolderCard extends StatefulWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final ValueChanged<FolderModel> onRenameRequest;
  final ValueChanged<FolderModel> onDeleteRequest;

  const FolderCard({super.key, required this.folder, required this.onTap, required this.onRenameRequest, required this.onDeleteRequest});

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.98);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        widget.onTap();
      },
      onTapCancel: _onTapCancel,
      onLongPress: () {
        final folder = widget.folder;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ ListTile(leading: const Icon(Icons.edit), title: const Text('Rename'), onTap: () { Navigator.of(ctx).pop(); widget.onRenameRequest(folder); },), ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () { Navigator.of(ctx).pop(); widget.onDeleteRequest(folder); },), ],),),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_scale, _scale),
        curve: Curves.easeOut,
        child: Card(
          shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFFFD700), width: 2), borderRadius: BorderRadius.circular(12),),
          color: Colors.white,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Row(children: [ Expanded(child: Text('${folder.title} (${folder.notesCount})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis,)), ],), const SizedBox(height: 8), Flexible(fit: FlexFit.loose, child: LayoutBuilder(builder: (context, constraints) { return ConstrainedBox(constraints: BoxConstraints(maxHeight: constraints.maxHeight), child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: _buildPreviewZone(folder),),); }),), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('Last edit: ${folder.lastModifiedShort}', style: const TextStyle(fontSize: 12, color: Colors.grey)), const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), ],) ],),),),),
      ),
    );
  }

  Widget _buildPreviewZone(FolderModel folder) {
    if (folder.notesCount == 0) {
      return Center(child: Text('No notes yet', style: TextStyle(color: Colors.grey.shade600)),);
    }

    final previews = List.generate(folder.notesCount >= 3 ? 3 : folder.notesCount, (i) {
      if (i % 3 == 1) {
        return Row(children: [ Container(width: 36, height: 24, color: Colors.grey.shade300), const SizedBox(width: 8), Expanded(child: Text('Image', style: TextStyle(color: Colors.grey.shade700))), ]);
      } else if (i % 3 == 2) {
        return Row(children: [ const Icon(Icons.mic, size: 18), const SizedBox(width: 8), Expanded(child: Text('Voice note \u2022 Sep 1', style: TextStyle(color: Colors.grey.shade700))), ]);
      }
      return Text('\u2022 Review calculus concepts...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade800));
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: previews.map((w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: w)).toList(),);
  }
}
