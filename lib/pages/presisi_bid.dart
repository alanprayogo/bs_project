// presisi_bid.dart

import 'package:flutter/material.dart';
import 'analisis_bid.dart'; // Pastikan file ini tersedia

class PresisiBidPage extends StatelessWidget {
  static const routeName = '/presisi';

  const PresisiBidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildListItem(context, 'Opening', 'opening'),
          _buildListItem(context, 'Respon 1C', 'respon_1c'),
          _buildListItem(context, 'Respon 1D', 'respon_1d'),
          _buildListItem(context, 'Respon 1H', 'respon_1h'),
          _buildListItem(context, 'Respon 1S', 'respon_1s'),
          _buildListItem(context, 'Respon 1NT', 'respon_1nt'),
          _buildListItem(context, 'Respon 2C', 'respon_2c'),
          _buildListItem(context, 'Respon 2D', 'respon_2d'),
          _buildListItem(context, 'Respon 2H', 'respon_2h'),
          _buildListItem(context, 'Respon 2S', 'respon_2s'),
          _buildListItem(context, 'Respon 2NT', 'respon_2nt'),
          _buildListItem(context, 'Respon 3C', 'respon_3c'),
          _buildListItem(context, 'Respon 3D', 'respon_3d'),
          _buildListItem(context, 'Respon 3H', 'respon_3h'),
          _buildListItem(context, 'Respon 3S', 'respon_3s'),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title, String bidTypeKey) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pushNamed(
            context,
            AnalisisBidPage.routeName,
            arguments: bidTypeKey,
          );
        },
      ),
    );
  }
}