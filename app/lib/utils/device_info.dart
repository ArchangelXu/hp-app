import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:universal_io/io.dart';

DeviceInfo deviceInfo = DeviceInfo._internal();

class DeviceInfo {
  /// 顶层变量，单例模式
  DeviceInfo._internal();

  late AndroidDeviceInfo androidInfo;
  late IosDeviceInfo iosInfo;

  late String manufacturer;
  late String brand;
  late String model;
  late String os;

  late String appName;
  late String appPackageName;
  late String appVersion;
  late String buildNumber;
  late String webUA;

  Future<void> init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    appPackageName = packageInfo.packageName;
    appVersion = packageInfo.version;
    buildNumber = packageInfo.buildNumber;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      webUA = webBrowserInfo.userAgent!;
    } else {
      if (Platform.isAndroid) {
        androidInfo = await deviceInfo.androidInfo;
        manufacturer = androidInfo.manufacturer ?? "unknown";
        brand = androidInfo.brand ?? "unknown";
        model = androidInfo.model ?? "unknown";
        os = "Android ${androidInfo.version.release ?? "unknown"}";
        debugPrint(prettyJson((androidInfo.toMap())));
      } else if (Platform.isIOS) {
        iosInfo = await deviceInfo.iosInfo;
        manufacturer = "Apple";
        brand = iosInfo.model ?? "unknown";
        model = iosInfo.utsname.machine ?? "unknown";
        os = "iOS ${iosInfo.systemVersion ?? "unknown"}";
        debugPrint(prettyJson((iosInfo.toMap())));
      }
    }

    debugPrint(getUserAgent());
    debugPrint("DeviceInfo ready");
  }

  String getUserAgent() {
    // Mozilla/5.0 (Android 10; HUAWEI; HUAWEI; ANA-AN00) hooh/1.0.0
    if (kIsWeb) {
      // not used in web
      return "$webUA hooh/$appVersion";
    } else {
      return "Mozilla/5.0 ($os; $manufacturer; $brand; $model) hooh/$appVersion";
    }
  }
}
