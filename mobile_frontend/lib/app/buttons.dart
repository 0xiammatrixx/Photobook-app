import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final double? width; 
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity, // default to full width if not provided
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // basic curved edges
          ),
          padding: const EdgeInsets.symmetric(vertical: 16), // vertical padding
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
