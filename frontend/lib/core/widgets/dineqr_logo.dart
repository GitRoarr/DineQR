import 'package:flutter/material.dart';

/// Reusable DineQR logo widget.
///
/// Make sure you have the asset declared in pubspec.yaml, e.g.:
///
/// flutter:
///   assets:
///     - assets/images/dineqr_logo.png
class DineQrLogo extends StatelessWidget {
  const DineQrLogo({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/dineqr_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
