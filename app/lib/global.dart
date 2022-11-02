import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final GlobalRouteObserver<PageRoute> routeObserver = GlobalRouteObserver<PageRoute>();

bool globalHomeScreenIsInStack = false;
double globalDarkModeImageOpacity = 0.7;
int globalDarkModeImageAlpha = (255 * globalDarkModeImageOpacity).toInt();

final StateProvider<bool> globalKeyboardVisibilityProvider = StateProvider<bool>((ref) => false);
// final StateProvider<Locale?> globalLocaleProvider = StateProvider<Locale?>((ref) => const Locale("en"));
const DARK_MODE_SYSTEM = 0;
const DARK_MODE_LIGHT = 1;
const DARK_MODE_DARK = 2;
const DARK_MODE_VALUES = [
  DARK_MODE_SYSTEM,
  DARK_MODE_LIGHT,
  DARK_MODE_DARK,
];
final StateProvider<int> globalDarkModeProvider = StateProvider((ref) {
  return DARK_MODE_SYSTEM;
});

class GlobalRouteObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    print('didPush route: $route,previousRoute:$previousRoute');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    print('didPop route: $route,previousRoute:$previousRoute');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    print('didReplace newRoute: $newRoute,oldRoute:$oldRoute');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    print('didRemove route: $route,previousRoute:$previousRoute');
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    super.didStartUserGesture(route, previousRoute);
    print('didStartUserGesture route: $route,previousRoute:$previousRoute');
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
    print('didStopUserGesture');
  }
}
