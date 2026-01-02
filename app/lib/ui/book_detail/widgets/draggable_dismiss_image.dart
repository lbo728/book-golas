import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:book_golas/data/services/image_cache_manager.dart';

class DraggableDismissImage extends StatefulWidget {
  final Animation<double> animation;
  final Uint8List imageBytes;

  const DraggableDismissImage({
    super.key,
    required this.animation,
    required this.imageBytes,
  });

  @override
  State<DraggableDismissImage> createState() => _DraggableDismissImageState();
}

class _DraggableDismissImageState extends State<DraggableDismissImage> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);

    return FadeTransition(
      opacity: widget.animation,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.87 * opacity),
        body: GestureDetector(
          onVerticalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 100 ||
                details.velocity.pixelsPerSecond.dy.abs() > 500) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _dragOffset = 0;
                _isDragging = false;
              });
            }
          },
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DraggableDismissNetworkImage extends StatefulWidget {
  final Animation<double> animation;
  final String imageUrl;
  final String imageId;

  const DraggableDismissNetworkImage({
    super.key,
    required this.animation,
    required this.imageUrl,
    required this.imageId,
  });

  @override
  State<DraggableDismissNetworkImage> createState() =>
      _DraggableDismissNetworkImageState();
}

class _DraggableDismissNetworkImageState
    extends State<DraggableDismissNetworkImage> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);

    return FadeTransition(
      opacity: widget.animation,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.87 * opacity),
        body: GestureDetector(
          onVerticalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 100 ||
                details.velocity.pixelsPerSecond.dy.abs() > 500) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _dragOffset = 0;
                _isDragging = false;
              });
            }
          },
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'book_image_${widget.imageId}',
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        cacheManager: BookImageCacheManager.instance,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[800],
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
