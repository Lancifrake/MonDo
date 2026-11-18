import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total});

  final int current; // étape actuelle, à partir de 1
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: i < current ? AppColors.green : AppColors.track,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}