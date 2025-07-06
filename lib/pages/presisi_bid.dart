// lib/pages/presisi_bid.dart

import 'package:flutter/material.dart';
import 'analisis_bid.dart';

class PresisiBidPage extends StatelessWidget {
  static const routeName = '/presisi';

  const PresisiBidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Halaman
            const Text(
              'Biding Presisi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Grid View - Responsif
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // Tampil 2 kolom
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio:
                    2.0, // Lebih lebar sedikit, tidak terlalu tinggi
                children: [
                  _buildGridItem(context, 'Opening', 'prec_opening'),
                  _buildGridItem(context, 'Respon 1C', 'prec_respon_1c'),
                  _buildGridItem(context, 'Respon 1D', 'prec_respon_1d'),
                  _buildGridItem(context, 'Respon 1H', 'prec_respon_1h'),
                  _buildGridItem(context, 'Respon 1S', 'prec_respon_1s'),
                  _buildGridItem(context, 'Respon 1NT', 'prec_respon_1nt'),
                  _buildGridItem(context, 'Respon 2C', 'prec_respon_2c'),
                  _buildGridItem(context, 'Respon 2D', 'prec_respon_2d'),
                  _buildGridItem(context, 'Respon 2H', 'prec_respon_2h'),
                  _buildGridItem(context, 'Respon 2S', 'prec_respon_2s'),
                  _buildGridItem(context, 'Respon 2NT', 'prec_respon_2nt'),
                  _buildGridItem(context, 'Respon 3C', 'prec_respon_3c'),
                  _buildGridItem(context, 'Respon 3D', 'prec_respon_3d'),
                  _buildGridItem(context, 'Respon 3H', 'prec_respon_3h'),
                  _buildGridItem(context, 'Respon 3S', 'prec_respon_3s'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuat satu item grid
  Widget _buildGridItem(BuildContext context, String title, String bidTypeKey) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            AnalisisBidPage.routeName,
            arguments: {
              'jenisBid': title,
              'strategy': bidTypeKey,
            },
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
