import 'package:flutter/material.dart';

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  const StickyTabBarDelegate({
    required this.child,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: backgroundColor,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child || backgroundColor != oldDelegate.backgroundColor;
  }
}
