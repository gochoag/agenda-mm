import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StickyNote {
  final int id;
  final int userId;
  final String? username;
  final String content;
  final String color;
  final String fontFamily;
  final bool isPinned;
  final String? createdAt;
  final String? updatedAt;

  StickyNote({
    required this.id,
    required this.userId,
    this.username,
    required this.content,
    required this.color,
    this.fontFamily = 'handwriting',
    required this.isPinned,
    this.createdAt,
    this.updatedAt,
  });

  Color get colorValue {
    try {
      String hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFFFFF59D); // Amarillo post-it por defecto
    }
  }

  static TextStyle getFontTextStyle(
    String family, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color = Colors.black87,
  }) {
    switch (family) {
      case 'casual':
        return GoogleFonts.patrickHand(
          fontSize: fontSize + 1,
          fontWeight: fontWeight,
          color: color,
          height: 1.3,
        );
      case 'mono':
        return GoogleFonts.robotoMono(
          fontSize: fontSize - 1,
          fontWeight: fontWeight,
          color: color,
          height: 1.35,
        );
      case 'clean':
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.3,
        );
      case 'handwriting':
      default:
        return GoogleFonts.kalam(
          fontSize: fontSize + 1,
          fontWeight: fontWeight,
          color: color,
          height: 1.3,
        );
    }
  }

  TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color = Colors.black87,
  }) {
    return getFontTextStyle(
      fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  factory StickyNote.fromJson(Map<String, dynamic> json) {
    return StickyNote(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String?,
      content: json['content'] as String? ?? '',
      color: json['color'] as String? ?? '#FFF59D',
      fontFamily: json['font_family'] as String? ?? 'handwriting',
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'content': content,
      'color': color,
      'font_family': fontFamily,
      'is_pinned': isPinned,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
