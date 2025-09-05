import 'package:flutter/material.dart';

/// Styled pages tabs bar that resembles the Figma-style tabs in the design.
class PagesTopBar extends StatefulWidget {
  final List<String> pages;
  final VoidCallback onOpenAllPages;

  const PagesTopBar({super.key, required this.pages, required this.onOpenAllPages});

  @override
  State<PagesTopBar> createState() => _PagesTopBarState();
}

class _PagesTopBarState extends State<PagesTopBar> {
  int _selected = 0;

  static const Color _primary = Color(0xFFD4AF37);
  static const Color _accent = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    final visible = pages.take(4).toList();
    final hiddenCount = (pages.length - visible.length).clamp(0, pages.length);

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
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
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
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 36,
                          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('\uff0b$hiddenCount', style: const TextStyle(color: Colors.white))),
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
