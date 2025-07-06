import 'package:flutter/material.dart';
import './widgets/CustomBottomNavigationBar.dart';
import 'pages/biding_page.dart';
import 'pages/kontrak_page.dart';
import 'pages/sistem_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/presisi_bid.dart';
import 'pages/sayc_bid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bid Snapper',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0E1431),
        scaffoldBackgroundColor: const Color(0xFF293A8F),
      ),
      home: const HomePage(),
      routes: {
        '/presisi': (context) => const PresisiBidPage(),
        '/sayc': (context) => const SaycBidPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    BidingPage(),
    KontrakPage(),
    SistemPage(),
    TutorialPage(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
