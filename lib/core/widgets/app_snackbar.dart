import 'package:flutter/material.dart';

class AppSnackBar {
  static void success(BuildContext context, String message) {
    final color = Theme.of(context).colorScheme.secondary; // success
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }

  static void error(BuildContext context, String message) {
    final color = Theme.of(context).colorScheme.error; // error
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }
}
