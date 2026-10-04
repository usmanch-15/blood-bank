import 'package:flutter/material.dart';

class UnsavedChangesGuard extends StatelessWidget {
  final bool dirty;
  final bool busy;
  final Widget child;
  final VoidCallback onDiscard;
  const UnsavedChangesGuard({
    super.key,
    required this.dirty,
    required this.busy,
    required this.onDiscard,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      final discard = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Discard unsaved changes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
      );
      if (discard == true && context.mounted) {
        onDiscard();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: child,
  );
}
