import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

extension DateTimeExtension on DateTime {
  static DateTime parseUtc(String formattedDate) => DateTime.parse('${formattedDate}z');

  static DateTime? tryParseUtc(String? formattedDate) {
    if (formattedDate != null) {
      return DateTime.tryParse('${formattedDate}z');
    }
    return null;
  }
}

extension UpdateStateExtension<T> on StateNotifier<T> {
  void updateState(T s) {
    state = s;
  }
}

extension RandomListExtension<T> on List<T> {
  /// return random element in this list
  T random() {
    if (isEmpty) {
      throw Exception("empty list");
    }
    return this[(length * Random().nextDouble()).toInt()];
  }
}

extension RandomMapExtension<K, V> on Map<K, V> {
  /// return random value in this map
  V randomValue() {
    if (isEmpty) {
      throw Exception("empty map");
    }
    return this[randomKey()]!;
  }

  /// return random key in this map
  K randomKey() {
    if (isEmpty) {
      throw Exception("empty map");
    }
    List list = keys.toList();
    return list.random();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
          '${alpha.toRadixString(16).padLeft(2, '0')}'
          '${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
