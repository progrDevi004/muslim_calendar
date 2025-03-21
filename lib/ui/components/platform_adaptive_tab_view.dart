import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine Datenklasse, die die Informationen für einen Tab enthält
class TabItem {
  final String title;
  final IconData androidIcon;
  final IconData iOSIcon;
  final Widget content;

  const TabItem({
    required this.title,
    required this.androidIcon,
    required this.iOSIcon,
    required this.content,
  });
}

/// Plattformadaptive Tab-Ansicht
/// Verwendet auf iOS ein Segmented Control, auf Android Material Tabs
class PlatformAdaptiveTabView extends StatefulWidget {
  final List<TabItem> tabs;
  final int initialIndex;
  final Color? activeColor;
  final Color? backgroundColor;
  final bool iOSTopPositioned;

  const PlatformAdaptiveTabView({
    Key? key,
    required this.tabs,
    this.initialIndex = 0,
    this.activeColor,
    this.backgroundColor,
    this.iOSTopPositioned = true, // true = oben, false = unten
  }) : super(key: key);

  @override
  State<PlatformAdaptiveTabView> createState() =>
      _PlatformAdaptiveTabViewState();
}

class _PlatformAdaptiveTabViewState extends State<PlatformAdaptiveTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  // iOS-Style Segmented Control für Tabs
  Widget _buildIOSTabBar() {
    return CupertinoSegmentedControl<int>(
      children: {
        for (int i = 0; i < widget.tabs.length; i++)
          i: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.tabs[i].title,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    _currentIndex == i ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
      },
      onValueChanged: (int index) {
        setState(() {
          _currentIndex = index;
          _tabController.animateTo(index);
        });
      },
      groupValue: _currentIndex,
      selectedColor: widget.activeColor ?? CupertinoColors.activeBlue,
      borderColor: widget.activeColor ?? CupertinoColors.activeBlue,
      unselectedColor: CupertinoColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  // Android-Style Material Tabs
  Widget _buildAndroidTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: widget.activeColor ?? Theme.of(context).primaryColor,
      unselectedLabelColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      indicatorColor: widget.activeColor ?? Theme.of(context).primaryColor,
      indicatorWeight: 2.0,
      tabs: widget.tabs
          .map((tab) => Tab(
                text: tab.title,
                icon: Icon(tab.androidIcon),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS-Stil mit CupertinoSegmentedControl
      return Column(
        children: [
          if (widget.iOSTopPositioned)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: _buildIOSTabBar(),
            ),
          Expanded(
            child: widget.tabs[_currentIndex].content,
          ),
          if (!widget.iOSTopPositioned)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: _buildIOSTabBar(),
            ),
        ],
      );
    } else {
      // Android-Stil mit Material Tabs
      return Column(
        children: [
          Container(
            color:
                widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
            child: _buildAndroidTabBar(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: widget.tabs.map((tab) => tab.content).toList(),
            ),
          ),
        ],
      );
    }
  }
}
