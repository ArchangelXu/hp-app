import 'dart:ui';

import 'package:app/global.dart';
import 'package:app/utils/network.dart';
import 'package:app/utils/styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

mixin KeyboardLogic<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final temp = keyboardVisible;
    if (_keyboardVisible == temp) return;
    _keyboardVisible = temp;
    onKeyboardChanged(keyboardVisible);
  }

  void onKeyboardChanged(bool visible);

  bool get keyboardVisible =>
      EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance.window.viewInsets,
        WidgetsBinding.instance.window.devicePixelRatio,
      ).bottom >
      100;
}

void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    duration: Duration(seconds: 2),
    content: Text(message),
  );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Widget buildAssetImageWidget(AssetEntity entity, {BoxFit fit = BoxFit.cover, int size = 200}) {
  return AssetEntityImage(
    entity,
    fit: fit,
    isOriginal: false, // Defaults to `true`.
    thumbnailSize: ThumbnailSize.square(size), // Preferred value.
    thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
  );
}

Future<T?> showHoohDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String barrierLabel = "",
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withOpacity(0.25),
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    pageBuilder: (ctx, anim1, anim2) => WillPopScope(child: builder(context), onWillPop: () => Future.value(barrierDismissible)),
    transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
      child: FadeTransition(
        child: child,
        opacity: anim1,
      ),
    ),
  );
}

class LoadingDialog extends ConsumerStatefulWidget {
  final LoadingDialogController _controller;

  const LoadingDialog(
    this._controller, {
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _LoadingDialogState();
}

class _LoadingDialogState extends ConsumerState<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            value: widget._controller.progress(),
          ),
        ),
      ),
    );
  }
}

class LoadingDialogController {
  bool hasProgress;
  double value = 0;
  double max = 100;

  LoadingDialogController({this.hasProgress = false});

  double? progress() {
    return hasProgress ? (value / max) : null;
  }
}

class HoohImage extends ConsumerWidget {
  const HoohImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.isBadge = false,
    this.cornerRadius = 0,
    this.placeholderWidget,
    this.errorWidget,
    this.onPress,
  }) : super(key: key);

  final String imageUrl;
  final double? width;
  final double? height;
  final bool? isBadge;
  final double cornerRadius;
  final Widget Function(BuildContext, String)? placeholderWidget;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final void Function()? onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget result = CachedNetworkImage(
      filterQuality: (isBadge ?? false) ? FilterQuality.none : FilterQuality.low,
      width: width,
      fadeInCurve: Curves.easeOut,
      fadeOutCurve: Curves.easeOut,
      fadeInDuration: Duration(milliseconds: 250),
      fadeOutDuration: Duration(milliseconds: 250),
      placeholderFadeInDuration: Duration(milliseconds: 250),
      fit: BoxFit.cover,
      height: height,
      useOldImageOnUrlChange: true,
      cacheKey: network.getStorageImageKey(imageUrl),
      imageUrl: imageUrl,
      errorWidget: errorWidget ??
          (context, url, error) {
            return buildPlaceHolder();
          },
      placeholder: placeholderWidget != null
          ? placeholderWidget
          : (context, url) {
              return buildPlaceHolder();
              // return Container(color: Colors.red,);
            },
    );
    if (MainStyles.isDarkMode(ref)) {
      result = Opacity(
        opacity: globalDarkModeImageOpacity,
        child: result,
      );
    }
    if (cornerRadius != 0) {
      result = ClipRRect(
        child: result,
        borderRadius: BorderRadius.circular(cornerRadius),
      );
      // return ClipRRect(
      //   child: result,
      //   borderRadius: BorderRadius.circular(cornerRadius),
      // );
    }
    if (onPress != null) {
      result = Stack(
        children: [
          result,
          Material(
            type: MaterialType.transparency,
            child: Ink(
              child: InkWell(
                onTap: onPress,
                borderRadius: BorderRadius.circular(cornerRadius),
                child: SizedBox(
                  width: width,
                  height: height,
                ),
              ),
            ),
          )
        ],
      );
    }
    return result;
  }

  Widget buildPlaceHolder() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

class HoohIcon extends ConsumerWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit? fit;

  const HoohIcon(this.assetName, {this.width, this.height, this.color, this.fit, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (assetName.endsWith(".svg")) {
      return SvgPicture.asset(
        assetName,
        width: width,
        height: height,
        color: color,
        fit: fit ?? BoxFit.contain,
      );
    } else {
      Widget result = Image.asset(
        assetName,
        width: width,
        height: height,
        color: color,
        fit: fit,
      );
      if (MainStyles.isDarkMode(ref)) {
        result = Opacity(
          opacity: globalDarkModeImageOpacity,
          child: result,
        );
      }
      return result;
    }
  }
}
