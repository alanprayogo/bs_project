// biding_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class BidingPage extends StatelessWidget {
  const BidingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Pilih Sistem Biding',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildCard(context, 'Presisi', Icons.menu_book, isComingSoon: false, pageIndex: 4),
                  _buildCard(context, 'SAYC', Icons.menu_book, isComingSoon: false, pageIndex: 5),
                  _buildCard(context, '2/1', Icons.menu_book, isComingSoon: true, pageIndex: null),
                  _buildCard(context, 'ACCL', Icons.menu_book, isComingSoon: true, pageIndex: null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon, {
    required bool isComingSoon,
    int? pageIndex,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isComingSoon) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur ini belum tersedia (Coming Soon)')),
            );
          } else if (pageIndex != null) {
            context.read<NavigationProvider>().goToPage(pageIndex);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.lightBlue),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}