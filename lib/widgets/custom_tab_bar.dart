import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<Widget> tabs;

  const CustomTabBar({super.key, required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicator: AppTheme.tabPillDecoration,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: AppTheme.tabIndicatorPadding,
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      labelPadding: EdgeInsets.zero,
      tabAlignment: TabAlignment.fill,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelColor: Colors.white,
      unselectedLabelColor: AppTheme.darkTextColor,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      tabs: tabs,
    );
  }
}
