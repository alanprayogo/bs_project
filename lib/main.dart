// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'main_app_layout.dart';
import 'pages/presisi_bid.dart';
import 'pages/analisis_bid.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NavigationProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Biding',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0E1431),
        scaffoldBackgroundColor: const Color(0xFF293A8F),
      ),
      home: MainAppLayout(),
      routes: {
        // Semua named routes didefinisikan di sini
        PresisiBidPage.routeName: (context) => const PresisiBidPage(),
        AnalisisBidPage.routeName: (context) {
          return AnalisisBidPage();
        },
      },
    );
  }
}
