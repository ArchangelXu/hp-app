import 'package:app/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class DesignColor {
  Color auto(WidgetRef ref);

  const DesignColor();
}

class SolidColor extends DesignColor {
  final Color generic;

  const SolidColor(this.generic);

  @override
  Color auto(WidgetRef ref) {
    return generic;
    // int darkMode = ref.watch(globalDarkModeProvider.state).state;
    // switch (darkMode) {
    //   case DARK_MODE_LIGHT:
    //     return generic;
    //   case DARK_MODE_DARK:
    //     return generic.withAlpha(globalDarkModeImageAlpha);
    //   case DARK_MODE_SYSTEM:
    //   default:
    //     Brightness brightness = SchedulerBinding.instance.window.platformBrightness;
    //     return brightness == Brightness.light ? generic : generic.withAlpha(globalDarkModeImageAlpha);
    // }
  }
}

class DayNightColor extends DesignColor {
  final Color light;
  final Color dark;

  const DayNightColor(this.light, this.dark);

  @override
  Color auto(WidgetRef ref) {
    int darkMode = ref.watch(globalDarkModeProvider);
    switch (darkMode) {
      case DARK_MODE_LIGHT:
        return light;
      case DARK_MODE_DARK:
        return dark;
      case DARK_MODE_SYSTEM:
      default:
        Brightness brightness = SchedulerBinding.instance.window.platformBrightness;
        return brightness == Brightness.light ? light : dark;
    }
  }
}

DesignColors designColors = DesignColors._internal();

class DesignColors {
  late final DayNightColor bar90_1;
  late final DayNightColor dark_00;
  late final DayNightColor dark_01;
  late final DayNightColor dark_03;
  late final DayNightColor light_00;
  late final DayNightColor light_01;
  late final DayNightColor light_02;
  late final DayNightColor light_03;
  late final DayNightColor light_06;
  late final DayNightColor light_20;
  late final DayNightColor neutrals_1;
  late final DayNightColor neutrals_4;
  late final DayNightColor neutrals_6;
  late final SolidColor blue;
  late final SolidColor blueLight;

  DesignColors._internal() {
    bar90_1 = const DayNightColor(Color(0xE6FFFFFF), Color(0xE6212121));
    dark_00 = const DayNightColor(Color(0xFF151515), Color(0xFFFBFBFB));
    dark_01 = const DayNightColor(Color(0xFF212121), Color(0xFFEAEAEA));
    dark_03 = const DayNightColor(Color(0xFFC4C4C4), Color(0xFF6F6F6F));
    light_00 = const DayNightColor(Color(0xFFFCFCFC), Color(0xFF151515));
    light_01 = const DayNightColor(Color(0xFFFFFFFF), Color(0xFF212121));
    light_02 = const DayNightColor(Color(0xFFEBEBEB), Color(0xFF6F6F6F));
    light_03 = const DayNightColor(Color(0xFF6F6F6F), Color(0xFFC4C4C4));
    light_06 = const DayNightColor(Color(0xFF707070), Color(0xFFC4C4C4));
    light_20 = const DayNightColor(Color(0x33FFFFFF), Color(0x33141416));
    neutrals_1 = const DayNightColor(Color(0xFF141416), Color(0xFFFFFFFF));
    neutrals_4 = const DayNightColor(Color(0xFF777E90), Color(0xFFE8E8E8));
    neutrals_6 = const DayNightColor(Color(0xFFE6E8EC), Color(0xFF6F6F6F));
    blue = const SolidColor(Color(0xFF38BAFF));
    blueLight = const SolidColor(Color(0xFF50FDF6));
  }
}
