import 'dart:async';
import 'dart:ui';

import 'package:app/global.dart';
import 'package:app/ui/pages/home.dart';
import 'package:app/utils/design_colors.dart';
import 'package:app/utils/device_info.dart';
import 'package:app/utils/network.dart';
import 'package:app/utils/preferences.dart';
import 'package:app/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';

// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// import 'package:jshare_flutter_plugin/jshare_flutter_plugin.dart';
import 'package:path_provider/path_provider.dart';

class Launcher {
  static const KEY_ADMIN_MODE = "KEY_ADMIN_MODE";

  Future<void> prepare() async {
    WidgetsFlutterBinding.ensureInitialized();
    // enableImmersiveMode();
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    await _initUtils();
  }

  Future<void> _initUtils() async {
    await _initSyncUtils();
    _initASyncUtils();
  }

  ///需要同步初始化的工具类
  Future<void> _initSyncUtils() async {
    await preferences.init();
    await deviceInfo.init();
  }

  Future<String> _documentsDirectory() async {
    if (kIsWeb) return '.';
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<String> _cacheDirectory() async {
    if (kIsWeb) return '.';
    return (await getTemporaryDirectory()).path;
  }

  ///不需要同步初始化的工具类
  void _initASyncUtils() {}
}

class HoohApp extends ConsumerStatefulWidget {
  const HoohApp({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _HoohAppState();
}

class _HoohAppState extends ConsumerState<HoohApp> with WidgetsBindingObserver, KeyboardLogic {
  late Brightness brightness;

  @override
  void onKeyboardChanged(bool visible) {
    ref.read(globalKeyboardVisibilityProvider.state).state = visible;
  }

  @override
  void initState() {
    super.initState();
    SingletonFlutterWindow window = WidgetsBinding.instance.window;
    window.onPlatformBrightnessChanged = () {
      WidgetsBinding.instance.handlePlatformBrightnessChanged();
      // This callback is called every time the brightness changes.
      setState(() {
        // 强制build
        brightness = window.platformBrightness;
      });
    };
    preferences.putInt(Preferences.KEY_SERVER, Network.TYPE_STAGING);
    network.reloadServerType();
  }

  @override
  Widget build(BuildContext context) {
    int darkMode = ref.watch(globalDarkModeProvider);
    brightness = SchedulerBinding.instance.window.platformBrightness;
    debugPrint("DesignColor brightness=$brightness");
    var themeData = ThemeData(
        primaryColor: designColors.bar90_1.auto(ref),
        backgroundColor: designColors.light_00.auto(ref),
        dialogBackgroundColor: designColors.light_00.auto(ref),
        scaffoldBackgroundColor: designColors.light_00.auto(ref),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: designColors.bar90_1.auto(ref),
          titleTextStyle: TextStyle(color: designColors.dark_01.auto(ref), fontWeight: FontWeight.bold, fontSize: 16),
          actionsIconTheme: IconThemeData(color: designColors.dark_01.auto(ref)),
          iconTheme: IconThemeData(color: designColors.dark_01.auto(ref)),
          foregroundColor: designColors.blue.generic,
          toolbarTextStyle: TextStyle(color: designColors.blue.generic, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        listTileTheme: ListTileThemeData(textColor: designColors.dark_01.auto(ref)),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: designColors.light_00.auto(ref),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        }),
        dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: designColors.dark_01.auto(ref),
            ),
            contentTextStyle: TextStyle(
              color: designColors.dark_01.auto(ref),
              fontSize: 16,
            )),
        checkboxTheme: CheckboxThemeData(
            checkColor: MaterialStateProperty.all(designColors.light_01.auto(ref)),
            fillColor: MaterialStateProperty.all(designColors.dark_01.auto(ref)),
            side: BorderSide(color: designColors.dark_01.auto(ref), width: 1),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(4),
              ),
            )),
        tabBarTheme: TabBarTheme(
            labelPadding: EdgeInsets.symmetric(horizontal: 8),
            labelStyle: TextStyle(
              color: designColors.dark_01.auto(ref),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              color: designColors.dark_01.auto(ref),
              fontSize: 16,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: designColors.dark_01.auto(ref), width: 2),
            )),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(textStyle: MaterialStateProperty.all(TextStyle(fontSize: 16, color: designColors.blue.generic, fontWeight: FontWeight.bold)))));
    return MaterialApp(
      navigatorObservers: [routeObserver],
      theme: themeData,
      // darkTheme: themeData.copyWith(brightness: Brightness.dark),
      themeMode: getThemeMode(darkMode),
      title: 'Hyperbound Flutter Demo',
      // home: HomeScreen(),
      home: const HomeScreen(),
      // debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (kReleaseMode) {
          return Scaffold(
            body: child!,
          );
        } else {
          return Scaffold(
            body: Stack(
              children: [
                child!,
                Positioned(
                  top: 0,
                  left: 48,
                  // left: MediaQuery.of(context).size.width * 0.3,
                  child: SafeArea(
                    child: ElevatedButton(
                        style: TextButton.styleFrom(
                          backgroundColor: designColors.light_01.auto(ref),
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          int darkMode = ref.watch(globalDarkModeProvider);
                          darkMode = cycleDarkMode(darkMode);
                          ref.read(globalDarkModeProvider.state).state = darkMode;
                          preferences.putInt(Preferences.KEY_DARK_MODE, darkMode);
                        },
                        child: Icon(
                          getIcon(darkMode),
                          color: designColors.dark_01.auto(ref),
                        )),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  IconData getIcon(int darkModeValue) {
    switch (darkModeValue) {
      case DARK_MODE_LIGHT:
        return Icons.light_mode;
      case DARK_MODE_DARK:
        return Icons.dark_mode;
      case DARK_MODE_SYSTEM:
      default:
        return Icons.brightness_medium;
    }
  }

  ThemeMode getThemeMode(int darkModeValue) {
    switch (darkModeValue) {
      case DARK_MODE_LIGHT:
        return ThemeMode.light;
      case DARK_MODE_DARK:
        return ThemeMode.dark;
      case DARK_MODE_SYSTEM:
      default:
        return ThemeMode.system;
    }
  }

  int cycleDarkMode(int current) {
    current += 1;
    if (current >= DARK_MODE_VALUES.length) {
      current = 0;
    }
    return current;
  }
}
