import 'package:flutter/material.dart';

/// شريط سفلي موحّد للاستخدام في جميع الشاشات
/// تخطيط: على اليسار -> [Home, Tasks]  في الوسط -> [NOTES] بارز
/// على اليمين -> [Statistics, Settings]
class UnifiedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const UnifiedBottomBar({Key? key, this.currentIndex = 0, this.onTap}) : super(key: key);

  static const Color kWhite = Colors.white;
  static const Color kBlack = Colors.black;
  static const Color kGold = Color(0xFFFFD700);

  void _handleTap(int index) {
    if (onTap != null) onTap!(index);
  }

  Widget _buildBarIcon({required IconData icon, required String label, required int index}) {
    final bool selected = index == currentIndex;
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? kGold : kBlack, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? kGold : kBlack, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            top: 18,
            child: Container(
              decoration: BoxDecoration(
                color: kWhite,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [const SizedBox(width: 8), _buildBarIcon(icon: Icons.home, label: 'الرئيسية', index: 0), _buildBarIcon(icon: Icons.task, label: 'المهام', index: 1)]),
                  const SizedBox(width: 88),
                  Row(children: [ _buildBarIcon(icon: Icons.bar_chart, label: 'الإحصائيات', index: 3), _buildBarIcon(icon: Icons.settings, label: 'الإعدادات', index: 4), const SizedBox(width: 8), ]),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: GestureDetector(
              onTap: () => _handleTap(2),
              child: Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.note_alt, color: kBlack, size: 30),
                    SizedBox(height: 2),
                    Text('ملاحظات', style: TextStyle(color: kBlack, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
