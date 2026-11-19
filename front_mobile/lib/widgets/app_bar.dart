import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(
  BuildContext context,
  String title, {
  VoidCallback? onBack,
}) {
  return AppBar(
    // L'icône vient du thème (actionIconTheme) : la même sur tous les écrans.
    leading: BackButton(onPressed: onBack ?? () => Navigator.pop(context)),
    title: Text(title),
    titleSpacing: 0,
  );
}