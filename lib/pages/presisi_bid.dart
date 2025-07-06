import 'package:flutter/material.dart';

class PresisiBidPage extends StatelessWidget {
  static const routeName = '/presisi';
  const PresisiBidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presisi Bid')),
      body: const Center(child: Text('Halaman Presisi')),
    );
  }
}