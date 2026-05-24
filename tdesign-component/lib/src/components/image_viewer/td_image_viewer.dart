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
      showGeneralDialog(
        context: context,
        barrierDismissible: barrierDismissible ?? false,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: modalBarrierColor,
        useRootNavigator: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return viewer;
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
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
