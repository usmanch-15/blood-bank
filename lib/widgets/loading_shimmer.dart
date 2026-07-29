import 'package:flutter/material.dart';

/// ✅ NEW — skeleton loading placeholders. Implemented with a plain
/// AnimationController (no extra pubspec dependency needed) rather than
/// pulling in the `shimmer` package just for this.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  /// Preset: a card-shaped shimmer block (for list items while loading).
  const LoadingShimmer.card({super.key, this.height = 90})
      : width = double.infinity,
        borderRadius = const BorderRadius.all(Radius.circular(12));

  /// Preset: a circular avatar-shaped shimmer.
  const LoadingShimmer.circle({super.key, double size = 48})
      : width = size,
        height = size,
        borderRadius = null;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.borderRadius == null && widget.width == widget.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0 → 1 looping
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

/// A ready-made "list of cards" skeleton — drop this in wherever a
/// StreamBuilder/FutureBuilder is in its loading (`ConnectionState.waiting`) state.
class LoadingShimmerList extends StatelessWidget {
  final int itemCount;

  const LoadingShimmerList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
            (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LoadingShimmer.card(),
        ),
      ),
    );
  }
}