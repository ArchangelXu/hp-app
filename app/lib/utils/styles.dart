import 'package:app/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MainStyles {
  static bool isDarkMode(WidgetRef ref) {
    int darkMode = ref.watch(globalDarkModeProvider);
    switch (darkMode) {
      case DARK_MODE_LIGHT:
        return false;
      case DARK_MODE_DARK:
        return true;
      case DARK_MODE_SYSTEM:
      default:
        Brightness brightness = SchedulerBinding.instance.window.platformBrightness;
        return brightness != Brightness.light;
    }
  }
}
