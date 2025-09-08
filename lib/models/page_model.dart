import 'package:flutter/material.dart';

class PageModel {
  String id;
  String title;
  int folderCount;
  DateTime lastModified;
  Color color;

  PageModel({
    required this.id,
    required this.title,
    this.folderCount = 0,
    DateTime? lastModified,
    Color? color,
  })  : lastModified = lastModified ?? DateTime.now(),
        color = color ?? const Color(0xFFD4AF37);
}
