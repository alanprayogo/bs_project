import 'package:flutter/material.dart';

class SaycBidPage extends StatelessWidget {
  static const routeName = '/sayc';
  const SaycBidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SAYC Bid')),
      body: const Center(child: Text('Halaman SAYC')),
    );
  }
}