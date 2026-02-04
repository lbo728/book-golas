import 'package:flutter/material.dart';

class LiquidGlassTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final double indicatorWeight;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  const LiquidGlassTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorWeight = 3,
    this.labelStyle,
    this.unselectedLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: controller,
      labelColor: labelColor ?? (isDark ? Colors.white : Colors.black),
      unselectedLabelColor: unselectedLabelColor ??
          (isDark ? Colors.grey[600] : Colors.grey[400]),
      indicatorColor: indicatorColor ?? Colors.white,
      indicatorWeight: indicatorWeight,
      labelStyle: labelStyle ??
          const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
      unselectedLabelStyle: unselectedLabelStyle,
      tabs: tabs.map((tab) => Tab(text: tab)).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
