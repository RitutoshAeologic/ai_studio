import 'package:flutter/material.dart';

/// Wraps any widget tree so that tapping anywhere outside a focused input
/// dismisses the keyboard / unfocuses the active field.
/// Uses [FocusScope.of(context).unfocus()] which correctly resigns the
/// iOS first responder (required for keyboard dismissal on iOS).
class UnfocusOnTap extends StatelessWidget {
  final Widget child;
  const UnfocusOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
