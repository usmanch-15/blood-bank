import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
              title: Text(AppLocalizations.of(context).discardChanges),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppLocalizations.of(context).keepEditing),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(AppLocalizations.of(context).discard),
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
