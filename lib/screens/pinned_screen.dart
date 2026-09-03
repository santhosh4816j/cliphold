import 'package:flutter/material.dart';
import 'history_screen.dart';

class PinnedScreen extends StatelessWidget {
  const PinnedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryScreen(pinnedOnly: true);
  }
}
