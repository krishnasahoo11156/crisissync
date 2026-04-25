import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Shimmer loading skeleton for dark theme.
class LoadingSkeleton extends StatefulWidget {
  final int rows;
  final double height;

  const LoadingSkeleton({super.key, this.rows = 4, this.height = 52});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.rows,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + (2.0 * _controller.value), 0),
                  end: Alignment(-1.0 + (2.0 * _controller.value) + 1.0, 0),
                  colors: const [
                    AppColors.surface,
                    AppColors.surfaceBright,
                    AppColors.surface,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
