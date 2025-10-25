import 'package:flutter/material.dart';
import 'home.dart';
import 'tools.dart';
import 'health.dart';

import 'bottom_nav_bar.dart';


class FinancesPage extends StatefulWidget {
  @override
  _FinancePageState createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancesPage> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ToolsPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HealthPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FinancesPage()),
        );
        break;
      case 4:
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance'),
      ),
      body: Center(
        child: Text('Welcome to the Finance Page!'),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}