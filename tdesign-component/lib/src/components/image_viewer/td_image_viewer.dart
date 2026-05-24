import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/td_colors.dart';
import '../../theme/td_theme.dart';
import 'td_image_viewer_widget.dart';

/// 图片预览工具
class TDImageViewer {
  /// 根据图片资源生成默认 [Hero] tag，可与列表缩略图共用。
  static Object heroTag(dynamic image, [int? index]) {
    if (image is String) {
      return index != null ? '$image#$index' : image;
    }
    if (image is File) {
      final path = image.path;
      return index != null ? '$path#$index' : path;
    }
    return index != null ? '${image.hashCode}#$index' : image.hashCode;
  }

  /// 构建 Hero 动画使用的图片，需与预览页 [buildHeroImage] 使用相同图片源。
  static Widget buildHeroImage(
    dynamic image, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (image is File) {
      return Image.file(
        image,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
      );
    }
    if (image is String) {
      if (image.startsWith('http')) {
        return Image.network(
          image,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
        );
      }
      return Image.asset(
        image,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
      );
    }
    throw FlutterError('image $image type is not supported');
  }

  /// 包裹缩略图以支持进入预览时的 Hero 动画。
  static Widget wrapHero({
    required Object tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  /// 显示图片预览
  static void showImageViewer({
    required BuildContext context,
    required List<dynamic> images,
    List<String>? labels,
    bool? closeBtn = true,
    bool? deleteBtn = false,
    bool? showIndex = false,
    bool? loop = false,
    bool? autoplay = false,
    int? duration,
    Color? bgColor,
    Color? navBarBgColor,
    Color? iconColor,
    TextStyle? labelStyle,
    TextStyle? indexStyle,
    Color? modalBarrierColor,
    bool? barrierDismissible,
    int? defaultIndex,
    double? width,
    double? height,
    OnIndexChange? onIndexChange,
    OnClose? onClose,
    OnDelete? onDelete,
    bool? ignoreDeleteError,
    OnImageTap? onTap,
    OnLongPress? onLongPress,
    LeftItemBuilder? leftItemBuilder,
    RightItemBuilder? rightItemBuilder,
    List<Object>? heroTags,
  }) {
    modalBarrierColor ??= TDTheme.of(context).fontGyColor1;
    final viewer = TDImageViewerWidget(
      images: images,
      labels: labels,
      closeBtn: closeBtn,
      deleteBtn: deleteBtn,
      showIndex: showIndex,
      loop: loop,
      autoplay: autoplay,
      duration: duration,
      bgColor: bgColor,
      navBarBgColor: navBarBgColor,
      iconColor: iconColor,
      labelStyle: labelStyle,
      indexStyle: indexStyle,
      defaultIndex: defaultIndex,
      onIndexChange: onIndexChange,
      width: width,
      height: height,
      onClose: onClose,
      onDelete: onDelete,
      ignoreDeleteError: ignoreDeleteError,
      onTap: onTap,
      onLongPress: onLongPress,
      leftItemBuilder: leftItemBuilder,
      rightItemBuilder: rightItemBuilder,
      heroTags: heroTags,
    );
    final useHero = heroTags != null && heroTags.isNotEmpty;
    if (useHero) {
      Navigator.of(context).push<void>(
        _TDImageViewerPageRoute(
          barrierDismissible: barrierDismissible ?? false,
          barrierColor: modalBarrierColor,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          builder: (_) => viewer,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible ?? false,
      barrierColor: modalBarrierColor,
      useSafeArea: false,
      builder: (context) => viewer,
    );
  }
}

/// Hero 动画需使用 [PageRoute]，Dialog 路由不会触发 Hero 过渡。
class _TDImageViewerPageRoute<T> extends PageRoute<T> {
  _TDImageViewerPageRoute({
    required this.builder,
    required this.barrierDismissible,
    required this.barrierColor,
    this.barrierLabel,
  });

  final WidgetBuilder builder;
  @override
  final bool barrierDismissible;
  @override
  final Color barrierColor;
  @override
  final String? barrierLabel;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
