import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Status indicator with animated dot.
class StatusIndicator extends StatelessWidget {
  final String status;
  final bool showLabel;

  const StatusIndicator({super.key, required this.status, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForStatus(status);
    final isAnimated = status != 'resolved';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAnimated)
          _PulsingDot(color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            _labelForStatus(status),
            style: AppTextStyles.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  String _labelForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'accepted':
        return 'Accepted';
      case 'responding':
        return 'Responding';
      case 'escalated':
        return 'Escalated';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.8),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 1.0 - _controller.value),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Core dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
