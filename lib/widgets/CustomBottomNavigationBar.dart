// lib/widgets/CustomBottomNavigationBar.dart

import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<BottomNavItem> items = [
      BottomNavItem(icon: Icons.card_giftcard, label: 'Binding'),
      BottomNavItem(icon: Icons.description, label: 'Kontrak'),
      BottomNavItem(icon: Icons.book, label: 'Sistem'),
      BottomNavItem(icon: Icons.help, label: 'Tutorial'),
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1431), // Background utama
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          int index = items.indexOf(item);
          bool isActive = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onItemSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isActive
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive ? Colors.lightBlue : Colors.grey,
                      size: 24,
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}
