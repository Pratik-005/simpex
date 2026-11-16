import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class Loader extends StatelessWidget {
  final double size;
  final Color? color;

  const Loader({
    super.key,
    this.size = 46.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
