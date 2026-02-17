import 'package:flutter/material.dart';
import '../home.dart';
import '../tools.dart';
import '../health.dart';
import '../personal.dart';


class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build),
          label: 'Tools',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.health_and_safety),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Personal',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: const Color.fromARGB(255, 114, 7, 124),
      unselectedItemColor: Colors.grey[600],
      onTap: onItemTapped,
    );
  }
}