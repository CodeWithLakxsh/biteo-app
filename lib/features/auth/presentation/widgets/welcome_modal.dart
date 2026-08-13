import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeModal extends StatelessWidget {
  final VoidCallback onDismiss;
  const WelcomeModal({super.key, required this.onDismiss});

  static void show(BuildContext context, VoidCallback onDismiss) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WelcomeModal(onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Welcome to Biteo! 🍔', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Discover the best gourmet food near you.', 
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDismiss, 
              child: const Text("Let's Eat"),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}