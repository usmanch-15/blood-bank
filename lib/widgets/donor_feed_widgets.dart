import 'package:flutter/material.dart';

class DonorFeedStateView extends StatelessWidget {
  final bool loading;
  final Object? error;
  final List<Widget> children;
  final VoidCallback? onRetry;
  const DonorFeedStateView({
    super.key,
    required this.loading,
    this.error,
    this.children = const [],
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Unable to load requests'),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (children.isEmpty) {
      return const Center(child: Text('No blood requests nearby.'));
    }
    return Column(children: children);
  }
}

class DonorMarkerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String bloodGroup;
  const DonorMarkerAvatar({super.key, this.imageUrl, required this.bloodGroup});
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundImage:
        imageUrl == null || imageUrl!.isEmpty ? null : NetworkImage(imageUrl!),
    child: imageUrl == null || imageUrl!.isEmpty ? Text(bloodGroup) : null,
  );
}
