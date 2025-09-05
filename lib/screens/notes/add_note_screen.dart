import 'package:flutter/material.dart';
import '../../models/note_model.dart';

class AddNoteScreen extends StatefulWidget {
  final String folderId;
  const AddNoteScreen({super.key, required this.folderId});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleCtl = TextEditingController();
  final _contentCtl = TextEditingController();

  @override
  void dispose() {
    _titleCtl.dispose();
    _contentCtl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtl.text.trim();
    final content = _contentCtl.text.trim();
    if (title.isEmpty && content.isEmpty) return;
    final n = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      folderId: widget.folderId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New note'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: Colors.black))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(controller: _titleCtl, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 12),
            Expanded(child: TextField(controller: _contentCtl, decoration: const InputDecoration(hintText: 'Content'), maxLines: null, expands: true)),
          ],
        ),
      ),
    );
  }
}
