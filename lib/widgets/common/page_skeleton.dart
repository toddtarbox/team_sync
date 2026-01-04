import 'package:flutter/material.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';

class PageSkeleton extends StatelessWidget {
  final Widget? body;
  final bool hasAppBar;
  final String title;

  const PageSkeleton({
    super.key,
    this.body,
    this.hasAppBar = true,
    this.title = '',
  });

  factory PageSkeleton.list({
    bool hasAppBar = true,
    String title = '',
    int itemCount = 8,
  }) {
    return PageSkeleton(
      hasAppBar: hasAppBar,
      title: title,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SkeletonContainer.circular(size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer.rectangular(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer.rectangular(
                        width: 100,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  factory PageSkeleton.grid({
    bool hasAppBar = true,
    String title = '',
    int itemCount = 12,
  }) {
    return PageSkeleton(
      hasAppBar: hasAppBar,
      title: title,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: SkeletonContainer.rectangular(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              SkeletonContainer.rectangular(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ),
    );
  }

  factory PageSkeleton.details({
    bool hasAppBar = true,
    String title = '',
  }) {
    return PageSkeleton(
      hasAppBar: hasAppBar,
      title: title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                SkeletonContainer.circular(size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      SkeletonContainer.rectangular(
                        width: double.infinity,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer.rectangular(
                        width: 150,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Content blocks
            SkeletonContainer.rectangular(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            SkeletonContainer.rectangular(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hasAppBar
          ? AppBar(
              title: title.isNotEmpty
                  ? Text(title)
                  : SkeletonContainer.rectangular(
                      width: 120,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
            )
          : null,
      body: body ??
          Center(
            child: SkeletonContainer.circular(size: 40),
          ),
    );
  }
}
