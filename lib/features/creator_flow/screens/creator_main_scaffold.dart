import 'package:flutter/material.dart';
import 'package:cthree/features/creator_flow/screens/dashboard.dart';
import 'package:cthree/features/creator_flow/screens/profile_screen.dart';

class CreatorMainScaffold extends StatefulWidget {
  const CreatorMainScaffold({super.key});

  @override
  State<CreatorMainScaffold> createState() => _CreatorMainScaffold();
}

class _CreatorMainScaffold extends State<CreatorMainScaffold> {
  int _selectedScreen = 0;

  final List<Widget> _screens = [
    const ContentPlannerScreen(),
    const CreatorProfileScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedScreen = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedScreen,
        children: _screens,
      ),

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Theme.of(context).colorScheme.surface),
        child: BottomNavigationBar(
          currentIndex: _selectedScreen,
          onTap: _onItemTapped,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: const Color(0xFF6F7685),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}