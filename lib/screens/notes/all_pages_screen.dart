import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import '../../models/page_model.dart';
import '../../repositories/notes_repository.dart';
import 'page_folders_screen.dart';

class AllPagesScreen extends StatefulWidget {
  final List<PageModel> pages;
  final ValueChanged<List<PageModel>> onChanged; // notify parent of reorder/edits

  const AllPagesScreen({super.key, required this.pages, required this.onChanged});

  @override
  State<AllPagesScreen> createState() => _AllPagesScreenState();
}

class _AllPagesScreenState extends State<AllPagesScreen> {
  late List<PageModel> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.pages);
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Create page'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Page name')),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Create'))],
    ));
    if (res != null && res.isNotEmpty) {
      setState(() => _pages.add(PageModel(id: DateTime.now().millisecondsSinceEpoch.toString(), title: res)));
      widget.onChanged(_pages);
    }
  }

  void _rename(PageModel p) async {
    final controller = TextEditingController(text: p.title);
    final res = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Rename page'),
      content: TextField(controller: controller),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save'))],
    ));
    if (res != null && res.isNotEmpty) {
      setState(() {
        final idx = _pages.indexWhere((x) => x.id == p.id);
        if (idx != -1) _pages[idx] = PageModel(id: p.id, title: res, folderCount: p.folderCount, lastModified: DateTime.now(), color: p.color);
      });
      widget.onChanged(_pages);
    }
  }

  void _changeColor(PageModel p) async {
    // Minimal color chooser
    final colors = [Colors.amber, Colors.redAccent, Colors.blueAccent, Colors.green];
    final res = await showDialog<Color>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Choose color'),
      content: Wrap(spacing: 8, children: colors.map((c) => GestureDetector(onTap: () => Navigator.of(ctx).pop(c), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))))).toList()),
    ));
    if (res != null) {
      setState(() {
        final idx = _pages.indexWhere((x) => x.id == p.id);
        if (idx != -1) _pages[idx] = PageModel(id: p.id, title: p.title, folderCount: p.folderCount, lastModified: DateTime.now(), color: res);
      });
      widget.onChanged(_pages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Pages'), backgroundColor: Colors.white, foregroundColor: Colors.black, actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog)]),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(builder: (context, constraints) {
          // responsive width available via constraints.maxWidth if needed

          // build keyed page widgets
          final pageWidgets = _pages.map((p) => SizedBox(
            key: ValueKey(p.id),
            width: 200,
            height: 220,
            child: _buildPageCard(p),
          )).toList();

          // children: pages + new page card
          final children = [...pageWidgets, SizedBox(key: const ValueKey('new_page'), width: 200, height: 220, child: _buildNewPageCard())];

          return SingleChildScrollView(
            child: ReorderableWrap(
              spacing: 12.0,
              runSpacing: 12.0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              needsLongPressDraggable: true,
              onReorder: (oldIndex, newIndex) {
                // if reorder attempts involve the new page tile (last index), ignore
                final lastIndex = children.length - 1;
                if (oldIndex == lastIndex || newIndex == lastIndex) return;

                setState(() {
                  final item = _pages.removeAt(oldIndex);
                  // adjust newIndex because children includes new_page at end
                  final adjNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  _pages.insert(adjNew, item);
                });
                widget.onChanged(_pages);
              },
              children: children,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPageCard(PageModel p) {
    return PageCard(
      page: p,
      onTap: () {
        // open the page and show its folders
        final repo = NotesRepository();
        final folders = repo.getFoldersForPage(p.title);
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PageFoldersScreen(pages: widget.pages, activeIndex: widget.pages.indexWhere((x) => x.id == p.id), page: p, folders: folders, onOpenFolder: (f) { Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => Container())); }, onAddFolder: () {}, onRenameRequest: (f) {}, onDeleteRequest: (f) {}, onOpenPageByIndex: (i) {
              final sel = widget.pages[i];
              final flds = repo.getFoldersForPage(sel.title);
              Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => PageFoldersScreen(pages: widget.pages, activeIndex: i, page: sel, folders: flds, onOpenFolder: (f) {}, onAddFolder: () {}, onRenameRequest: (f) {}, onDeleteRequest: (f) {}, onOpenPageByIndex: null)));
        })));
      },
      onRenameRequest: _rename,
      onChangeColorRequest: _changeColor,
      onDeleteRequest: (page) {
        setState(() {
          _pages.removeWhere((x) => x.id == page.id);
          widget.onChanged(_pages);
        });
      },
    );
  }

  Widget _buildNewPageCard() {
    return GestureDetector(
      onTap: _showCreateDialog,
      child: Container(
        height: 220,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1D5DB), width: 2),),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [ Icon(Icons.add_box_outlined, size: 40, color: Color(0xFF9CA3AF)), SizedBox(height: 8), Text('New page', style: TextStyle(color: Color(0xFF9CA3AF))), ],),),
      ),
    );
  }
}

class PageCard extends StatefulWidget {
  final PageModel page;
  final VoidCallback onTap;
  final ValueChanged<PageModel> onRenameRequest;
  final ValueChanged<PageModel> onChangeColorRequest;
  final ValueChanged<PageModel> onDeleteRequest;

  const PageCard({
    super.key,
    required this.page,
    required this.onTap,
    required this.onRenameRequest,
    required this.onChangeColorRequest,
    required this.onDeleteRequest,
  });

  @override
  State<PageCard> createState() => _PageCardState();
}

class _PageCardState extends State<PageCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.98);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final page = widget.page;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: () => _showPageActions(context, page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_scale, _scale),
        curve: Curves.easeOut,
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                            '${page.title} (${page.folderCount})',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Preview zone: a flexible area with small previews
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 0, maxHeight: constraints.maxHeight),
                          child: _buildPreviewZone(page),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

                  // Last edit + chevron. Use Expanded on the text so it can't overflow the row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Last edit: ${page.lastModified.toLocal().toString().split(' ').first}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPageActions(BuildContext context, PageModel page) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onRenameRequest(page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Change color'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onChangeColorRequest(page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onDeleteRequest(page);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewZone(PageModel page) {
    if (page.folderCount == 0) {
      return Center(
        child: Text('No folders yet', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final count = page.folderCount >= 3 ? 3 : page.folderCount;
    final previews = List<Widget>.generate(count, (i) {
      return Row(
        children: [
          const Icon(Icons.folder, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text('Folder ${i + 1}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
        ],
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: previews.map((w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: w)).toList(),
    );
  }
}
