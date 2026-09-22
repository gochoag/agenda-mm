import 'dart:convert';
import 'package:flutter/material.dart';

class CoverElement {
  final String id;
  final String type; // 'text', 'doodle_spiral', 'doodle_sparkle', 'sticker'
  String text;
  double x; // 0.0 a 1.0 (coordenadas relativas en el lienzo)
  double y; // 0.0 a 1.0
  double scale;
  double rotation; // radianes
  Color color;
  String fontFamily;
  double fontSize;
  String extra;

  CoverElement({
    required this.id,
    required this.type,
    this.text = '',
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.color,
    this.fontFamily = 'Caveat',
    this.fontSize = 24.0,
    this.extra = '',
  });

  factory CoverElement.fromJson(Map<String, dynamic> json) {
    return CoverElement(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      color: _colorFromHex(json['color'] as String? ?? '#E11D48'),
      fontFamily: json['fontFamily'] as String? ?? 'Caveat',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      extra: json['extra'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'color': _colorToHex(color),
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'extra': extra,
    };
  }

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFFE11D48);
  }

  static String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}

class MonthlyCover {
  final int? id;
  final int? userId;
  final String monthYear; // YYYY-MM
  String title;
  String subtitle;
  String yearText;
  String backgroundType; // 'grid', 'dots', 'ruled', 'clean'
  Color backgroundColor;
  List<CoverElement> elements;
  bool isCustom;

  MonthlyCover({
    this.id,
    this.userId,
    required this.monthYear,
    required this.title,
    required this.subtitle,
    required this.yearText,
    this.backgroundType = 'grid',
    this.backgroundColor = const Color(0xFFFFFDF7),
    required this.elements,
    this.isCustom = false,
  });

  factory MonthlyCover.fromJson(Map<String, dynamic> json) {
    List<CoverElement> elementsList = [];
    if (json['design_data'] != null) {
      try {
        dynamic parsed = json['design_data'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          elementsList = parsed
              .map((e) => CoverElement.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return MonthlyCover(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      monthYear: json['month_year'] as String? ?? '2026-09',
      title: json['title'] as String? ?? 'Septiembre',
      subtitle: json['subtitle'] as String? ?? 'Amor y Abundancia',
      yearText: json['year_text'] as String? ?? '2026',
      backgroundType: json['background_type'] as String? ?? 'grid',
      backgroundColor: CoverElement._colorFromHex(json['background_color'] as String? ?? '#FFFDF7'),
      elements: elementsList,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month_year': monthYear,
      'title': title,
      'subtitle': subtitle,
      'year_text': yearText,
      'background_type': backgroundType,
      'background_color': CoverElement._colorToHex(backgroundColor),
      'design_data': jsonEncode(elements.map((e) => e.toJson()).toList()),
      'is_custom': isCustom,
    };
  }
}
