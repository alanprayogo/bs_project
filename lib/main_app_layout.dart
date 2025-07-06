// main_app_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'pages/biding_page.dart';
import 'widgets/CustomBottomNavigationBar.dart';
import 'pages/kontrak_page.dart';
import 'pages/sistem_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/presisi_bid.dart';
import 'pages/sayc_bid.dart';

class MainAppLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    final List<Widget> _pages = [
      BidingPage(),        // index 0
      KontrakPage(),       // index 1
      SistemPage(),        // index 2
      TutorialPage(),      // index 3
      PresisiBidPage(),    // index 4
      SaycBidPage(),       // index 5
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bid Snapper',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E1431),
        elevation: 0,
      ),
      body: IndexedStack(
        index: navProvider.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onItemSelected: (index) {
          navProvider.goToPage(index);
        },
      ),
    );
  }
}