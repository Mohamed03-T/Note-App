import 'package:flutter/material.dart';
import '../../models/page_model.dart';

/// Styled pages tabs bar.
class PagesTopBar extends StatefulWidget {
  final List<String>? pages; // legacy
  final List<PageModel>? pageModels;
  final VoidCallback onOpenAllPages;
  final ValueChanged<int>? onPageSelected;
  final int? selectedIndex;
  const PagesTopBar({super.key, this.pages, this.pageModels, required this.onOpenAllPages, this.onPageSelected, this.selectedIndex}) : assert(pages != null || pageModels != null);

  @override
  State<PagesTopBar> createState() => _PagesTopBarState();
}

class _PagesTopBarState extends State<PagesTopBar> {
  int _selected = 0;

  static const Color _primary = Color(0xFFD4AF37);
  static const Color _accent = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    // sync controlled selectedIndex if provided
    if (widget.selectedIndex != null && widget.selectedIndex != _selected) {
      _selected = widget.selectedIndex!;
    }
    final names = widget.pageModels?.map((p) => p.title).toList() ?? widget.pages!;
    // show first 3 and a hidden counter as requested
    final visible = names.take(3).toList();
    final hiddenCount = (names.length - visible.length).clamp(0, names.length);

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selected = i);
                            widget.onPageSelected?.call(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: _selected == i ? _primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              visible[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selected == i ? Colors.white : _textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hiddenCount > 0)
                      GestureDetector(
                        onTap: widget.onOpenAllPages,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 36,
                          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('$hiddenCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
