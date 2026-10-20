import 'package:flutter/material.dart';

/// Small, dependency-free Stage H primitives shared by polished screens.
class StageHSpacing {
  static const page = EdgeInsets.all(16);
  static const section = EdgeInsets.only(top: 20, bottom: 8);
}

class StageHCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StageHCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(padding: padding, child: child),
      );
}

class StageHStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const StageHStatusChip({super.key, required this.label, required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(label: label, child: Chip(
      avatar: Icon(icon, size: 17, color: tone),
      label: Text(label),
      side: BorderSide(color: tone.withValues(alpha: 0.55)),
    ));
  }
}

class StageHPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const StageHPrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: icon == null
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label)),
      );
}
