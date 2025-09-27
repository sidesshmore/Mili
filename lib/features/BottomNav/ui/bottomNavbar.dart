import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Activities/ui/activitesScreen.dart';

import 'package:mindmate/features/Analytics/ui/analyticsScreen.dart';
import 'package:mindmate/features/Home/ui/homeScreen.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 1;
  final List<Widget> _widgetOptions = [
    const AnalyticsScreen(),
    const HomeScreen(),
    const ActivitiesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Globals.customBlue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  size: screenWidth * 0.06,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home, size: screenWidth * 0.06),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bolt, size: screenWidth * 0.06),
                label: '',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ],
      ),
    );
  }
}
