import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(
  BuildContext context,
  String title, {
  VoidCallback? onBack,
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.chevron_left, size: 32),
      onPressed: onBack ?? () => Navigator.pop(context),
    ),
    title: Text(title),
    titleSpacing: 0,
  );
}