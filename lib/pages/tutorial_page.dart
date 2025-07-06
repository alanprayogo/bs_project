// lib/pages/tutorial_page.dart
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Tutorial Page', style: TextStyle(color: Colors.white, fontSize: 20)),
    );
  }
}