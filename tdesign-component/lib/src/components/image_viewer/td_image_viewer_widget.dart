import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';

import '../../../tdesign_flutter.dart';
import '../navbar/td_nav_bar.dart';

typedef OnIndexChange = Function(int index);
typedef OnClose = Function(int index);
typedef OnDelete = Function(int index);
typedef OnImageTap = Function(int index);
typedef OnLongPress = Function(int index);
typedef LeftItemBuilder = Widget Function(BuildContext context, int index);
typedef RightItemBuilder = Widget Function(BuildContext context, int index);

class TDImageViewerWidget extends StatefulWidget {
  const TDImageViewerWidget({
    Key? key,
    this.closeBtn,
    this.deleteBtn,
    required this.images,
    this.labels,
    this.showIndex,
    this.loop,
    this.autoplay,
    this.duration,
    this.bgColor,
    this.navBarBgColor,
    this.iconColor,
    this.labelStyle,
    this.indexStyle,
    this.defaultIndex,
    this.onIndexChange,
    this.width,
    this.height,
    this.onClose,
    this.onDelete,
    this.ignoreDeleteError = false,
    this.onTap,
    this.onLongPress,
    this.leftItemBuilder,
    this.rightItemBuilder,
    this.heroTags,
    this.minScale,
    this.maxScale,
  }) : super(key: key);

  /// 是否展示关闭按钮
  final bool? closeBtn;

  /// 是否显示删除操作
  final bool? deleteBtn;

  /// 图片数组
  final List<dynamic> images;

  /// 图片描述
  final List<String>? labels;

  /// 是否显示页码
  final bool? showIndex;

  /// 图片是否循环
  final bool? loop;

  /// 图片轮播是否自动播放
  final bool? autoplay;

  /// 自动播放间隔
  final int? duration;

  /// 背景色
  final Color? bgColor;

  /// 导航栏背景色
  final Color? navBarBgColor;

  /// 图标颜色
  final Color? iconColor;

  /// label文字样式
  final TextStyle? labelStyle;

  /// 页码样式
  final TextStyle? indexStyle;

  /// 默认预览图片所在的下标
  final int? defaultIndex;

  /// 预览图片切换回调
  final OnIndexChange? onIndexChange;

  /// 关闭点击
  final OnClose? onClose;

  /// 删除点击
  final OnDelete? onDelete;

  /// 是否忽略单张图片删除错误提示
  final bool? ignoreDeleteError;

  /// 点击图片
  final OnImageTap? onTap;

  /// 长按图片
  final OnLongPress? onLongPress;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 左侧自定义操作
  final LeftItemBuilder? leftItemBuilder;

  /// 右侧自定义操作
  final RightItemBuilder? rightItemBuilder;

  /// Hero 动画 tag 列表，需与 [images] 一一对应；缩略图侧使用相同 tag 包裹 [Hero]。
  final List<Object>? heroTags;

  /// 图片最小缩放比例。
  final double? minScale;

  /// 图片最大缩放比例。
  final double? maxScale;

  @override
  State<StatefulWidget> createState() {
    return _TDImageViewerWidgetState();
  }
}

class _TDImageViewerWidgetState extends State<TDImageViewerWidget> {
  int _index = 1;
  int? _zoomingIndex;

  @override
  void initState() {
    super.initState();
    if (widget.images.isEmpty) {
      throw FlutterError('images must not be empty');
    }
    if ((widget.defaultIndex ?? 0) > widget.images.length - 1) {
      throw FlutterError('defaultIndex must be less than images.length');
    }
    if (widget.labels != null &&
        widget.images.length != widget.labels!.length) {
      throw FlutterError('labels.length must be equals images.length');
    }
    if (widget.heroTags != null &&
        widget.images.length != widget.heroTags!.length) {
      throw FlutterError('heroTags.length must be equals images.length');
    }
    final minScale = widget.minScale ?? 1.0;
    final maxScale = widget.maxScale ?? 3.0;
    if (minScale <= 0 || maxScale < minScale) {
      throw FlutterError('maxScale must be greater than or equal to minScale');
    }
    _index = (widget.defaultIndex ?? 0) + 1;
  }

  Widget _wrapHero(Widget child, int index) {
    final heroTags = widget.heroTags;
    if (heroTags == null || index < 0 || index >= heroTags.length) {
      return child;
    }
    return Hero(
      tag: heroTags[index],
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  Widget _getImage(dynamic image, int index) {
    var size = MediaQuery.of(context).size;
    var boxFit = ((widget.width != null) || (widget.height != null))
        ? BoxFit.fill
        : BoxFit.fitWidth;
    if (widget.heroTags != null) {
      return TDImageViewer.buildHeroImage(
        image,
        width: widget.width ?? size.width,
        height: widget.height,
        fit: boxFit == BoxFit.fitWidth ? BoxFit.contain : boxFit,
      );
    }
    var horizontal =
        widget.width != null ? (size.width - (widget.width ?? 0)) / 2 : 0.0;
    var vertical =
        widget.height != null ? (size.height - (widget.height ?? 0)) / 2 : 0.0;
    var margin = EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
    if (image is File) {
      return Container(
        margin: margin,
        child: TDImage(
          imageFile: image,
          fit: boxFit,
          type: TDImageType.fitWidth,
        ),
      );
    }
    if (image is String) {
      if (image.startsWith('http')) {
        return Container(
          margin: margin,
          child: TDImage(
            imgUrl: image,
            fit: boxFit,
            type: TDImageType.fitWidth,
            loadingWidget: Container(
              width: size.width,
              height: size.height,
              // todo
              color: TDTheme.of(context).fontGyColor1,
              child: Center(
                child: TDLoading(
                  icon: TDLoadingIcon.circle,
                  size: TDLoadingSize.large,
                  iconColor: TDTheme.of(context).brandNormalColor,
                ),
              ),
            ),
          ),
        );
      }
      return Container(
        margin: margin,
        child: TDImage(
          assetUrl: image,
          fit: boxFit,
          type: TDImageType.fitWidth,
        ),
      );
    }
    throw FlutterError('image ${image} type is not supported');
  }

  void _updateZooming(int index, bool isZooming) {
    if (!mounted) {
      return;
    }
    if (isZooming) {
      if (_zoomingIndex == index) {
        return;
      }
      setState(() {
        _zoomingIndex = index;
      });
      return;
    }
    if (_zoomingIndex != index) {
      return;
    }
    setState(() {
      _zoomingIndex = null;
    });
  }

  Widget _buildImageItem(dynamic image, int index) {
    final child = _wrapHero(_getImage(image, index), index);
    return RepaintBoundary(
      child: _TDImageZoomItem(
        key: ValueKey<Object>(widget.heroTags?[index] ?? '$index-$image'),
        minScale: widget.minScale ?? 1.0,
        maxScale: widget.maxScale ?? 3.0,
        onTap: () => widget.onTap?.call(index),
        onLongPress: () => widget.onLongPress?.call(index),
        onZoomingChanged: (isZooming) => _updateZooming(index, isZooming),
        child: child,
      ),
    );
  }

  TextStyle _mergeTextStyle(TextStyle? style, TextStyle defaults) {
    return (style ?? defaults).copyWith(decoration: TextDecoration.none);
  }

  Widget _buildLabelText(String text) {
    final defaults = TextStyle(
      color: TDTheme.of(context).textColorAnti,
      fontSize: 16,
      height: 1.0,
      decoration: TextDecoration.none,
    );
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _mergeTextStyle(widget.labelStyle, defaults),
    );
  }

  Widget _buildIndexText(String text, {bool withLabel = false}) {
    final defaults = TextStyle(
      color: withLabel
          ? TDTheme.of(context).brandClickColor
          : TDTheme.of(context).textColorAnti,
      fontSize: 10,
      height: 1.0,
      decoration: TextDecoration.none,
    );
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _mergeTextStyle(widget.indexStyle, defaults),
    );
  }

  Widget _getPageTitle() {
    if (widget.labels != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: (widget.labels![_index - 1]) != '',
            child: _buildLabelText(widget.labels![_index - 1]),
          ),
          Visibility(
            visible: widget.showIndex ?? false,
            child: _buildIndexText(
              '$_index / ${widget.images.length}',
              withLabel: true,
            ),
          ),
        ],
      );
    }
    if (!(widget.showIndex ?? false)) {
      return const SizedBox.shrink();
    }
    return _buildIndexText('$_index / ${widget.images.length}');
  }

  Widget _getLeft() {
    if (widget.leftItemBuilder != null) {
      return widget.leftItemBuilder!(context, _index - 1);
    }
    return GestureDetector(
      onTap: () {
        if (widget.onClose != null) {
          widget.onClose!.call(_index - 1);
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Icon(
        TDIcons.close,
        color: widget.iconColor ?? TDTheme.of(context).textColorAnti,
      ),
    );
  }

  Widget _getRight() {
    if (widget.rightItemBuilder != null) {
      return widget.rightItemBuilder!(context, _index - 1);
    }
    return Visibility(
      visible: widget.deleteBtn ?? false,
      child: GestureDetector(
        onTap: () {
          if (widget.images.length == 1 &&
              !(widget.ignoreDeleteError ?? false)) {
            throw FlutterError('images must not be empty');
          }
          widget.images.removeAt(_index - 1);
          widget.onDelete?.call(_index - 1);
          setState(() {
            if (_index > 1) {
              _index--;
            }
          });
        },
        child: Icon(
          TDIcons.delete,
          color: widget.iconColor ?? TDTheme.of(context).textColorAnti,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);
    var safeAreaHeight = media.padding.top;
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            // todo
            color: widget.bgColor ?? TDTheme.of(context).fontGyColor1,
          ),
        ),
        Positioned(
          top: safeAreaHeight,
          bottom: 0,
          left: 0,
          right: 0,
          child: Swiper(
            index: _index - 1,
            loop: widget.heroTags != null
                ? (widget.loop ?? false)
                : (widget.loop ?? true),
            autoplay: (widget.autoplay ?? false) && _zoomingIndex == null,
            duration: widget.duration ?? kDefaultAutoplayTransactionDuration,
            physics: _zoomingIndex != null
                ? const NeverScrollableScrollPhysics()
                : null,
            itemBuilder: (BuildContext context, int index) {
              var image = widget.images[index];
              return _buildImageItem(image, index);
            },
            itemCount: widget.images.length,
            onIndexChanged: (index) {
              _zoomingIndex = null;
              if ((widget.showIndex ?? false) || widget.labels != null) {
                setState(() {
                  _index = index + 1;
                });
              }
              widget.onIndexChange?.call(index);
            },
          ),
        ),
        SafeArea(
          child: Container(
            clipBehavior: Clip.hardEdge,
            color: widget.navBarBgColor ??
                TDTheme.of(context).textColorPlaceholder,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _getLeft(),
                Expanded(flex: 1, child: Center(child: _getPageTitle())),
                _getRight(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TDImageZoomItem extends StatefulWidget {
  const _TDImageZoomItem({
    Key? key,
    required this.child,
    required this.minScale,
    required this.maxScale,
    this.onTap,
    this.onLongPress,
    required this.onZoomingChanged,
  }) : super(key: key);

  final Widget child;
  final double minScale;
  final double maxScale;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool> onZoomingChanged;

  @override
  State<_TDImageZoomItem> createState() => _TDImageZoomItemState();
}

class _TDImageZoomItemState extends State<_TDImageZoomItem> {
  late final TransformationController _controller;
  Offset _doubleTapPosition = Offset.zero;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_handleScaleChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScaleChanged);
    widget.onZoomingChanged(false);
    _controller.dispose();
    super.dispose();
  }

  void _handleScaleChanged() {
    final isZooming =
        _controller.value.getMaxScaleOnAxis() > widget.minScale + 0.01;
    if (_isZooming == isZooming) {
      return;
    }
    _isZooming = isZooming;
    widget.onZoomingChanged(isZooming);
  }

  void _handleDoubleTap() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if (scale > widget.minScale + 0.01) {
      _controller.value = Matrix4.identity();
      return;
    }
    final targetScale = widget.maxScale > 2.0 ? 2.0 : widget.maxScale;
    _controller.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, _doubleTapPosition.dx * (1 - targetScale))
      ..setEntry(1, 3, _doubleTapPosition.dy * (1 - targetScale));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTapDown: (details) {
        _doubleTapPosition = details.localPosition;
      },
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        boundaryMargin: const EdgeInsets.all(80),
        clipBehavior: Clip.none,
        child: SizedBox.expand(
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
