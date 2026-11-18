import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(
  BuildContext context,
  String title, {
  VoidCallback? onBack,
  List<Widget>? actions,
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.chevron_left, size: 32),
      onPressed: onBack ?? () => Navigator.pop(context),
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    titleSpacing: 0,
    actions: actions,
  );
}