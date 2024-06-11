import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class CustomNavigationBar {
  final Function(int) onTabTapped;
  final int currentIndex;

  CustomNavigationBar({required this.onTabTapped, required this.currentIndex});

  Widget build() {
    return AnimatedBottomNavigationBar.builder(
      itemCount: 4,
      activeIndex: currentIndex,
      onTap: onTabTapped,
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.verySmoothEdge,
      leftCornerRadius: 32,
      rightCornerRadius: 32,
      tabBuilder: (int index, bool isActive) {
        final color = isActive ? Color(0xFFE8D6CA): Color(0xFF544C47);
        IconData iconData;
        switch (index) {
          case 0:
            iconData = Icons.home;
            break;
          case 1:
            iconData = Icons.calendar_month_rounded;
            break;
          case 2:
            iconData = Icons.insert_chart_rounded;
            break;
          case 3:
            iconData = Icons.person;
            break;
          default:
            iconData = Icons.error;
        }
        return Icon(
          iconData,
          size: 24,
          color: color,
        );
      },
    );
  }
}