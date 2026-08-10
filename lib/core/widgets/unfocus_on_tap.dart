import 'package:flutter/material.dart';

/// Wraps any widget tree so that tapping anywhere outside a focused input
/// dismisses the keyboard / unfocuses the active field.
class UnfocusOnTap extends StatelessWidget {
  final Widget child;
  const UnfocusOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
