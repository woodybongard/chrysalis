import 'package:flutter/material.dart';

class CenterMessageWithButton extends StatelessWidget {
  const CenterMessageWithButton({
    required this.message,
    required this.onPressed,
    super.key,
    this.scaleHeight = 1.0, // default if not passed
  });
  final String message;
  final VoidCallback onPressed;
  final double scaleHeight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: scaleHeight * 16),
          ElevatedButton(onPressed: onPressed, child: const Text('Reload')),
        ],
      ),
    );
  }
}
