import 'package:flutter/material.dart';

/// A shimmer effect widget for skeleton loading
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade800,
                Colors.grey.shade600,
                Colors.grey.shade800,
              ],
              stops: [0.0, (_animation.value + 2) / 4, 1.0],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton box for loading placeholders
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loading for a single transaction item
class TransactionSkeletonItem extends StatelessWidget {
  const TransactionSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon placeholder
          SkeletonBox(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 16),
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          // Amount placeholder
          SkeletonBox(width: 70, height: 20, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton loading for the transaction list
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const TransactionSkeletonItem(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading for the balance card
class BalanceCardSkeleton extends StatelessWidget {
  const BalanceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card name placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 100, height: 20, borderRadius: 4),
                SkeletonBox(width: 40, height: 24, borderRadius: 4),
              ],
            ),
            const Spacer(),
            // Balance label
            SkeletonBox(width: 80, height: 14, borderRadius: 4),
            const SizedBox(height: 8),
            // Balance amount
            SkeletonBox(width: 180, height: 36, borderRadius: 4),
            const SizedBox(height: 16),
            // Card number placeholder
            Row(
              children: [
                SkeletonBox(width: 40, height: 12, borderRadius: 4),
                const SizedBox(width: 12),
                SkeletonBox(width: 40, height: 12, borderRadius: 4),
                const SizedBox(width: 12),
                SkeletonBox(width: 40, height: 12, borderRadius: 4),
                const SizedBox(width: 12),
                SkeletonBox(width: 40, height: 12, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full home screen skeleton
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BalanceCardSkeleton(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick actions skeleton
                ShimmerEffect(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      4,
                      (index) => Column(
                        children: [
                          SkeletonBox(width: 56, height: 56, borderRadius: 16),
                          const SizedBox(height: 8),
                          SkeletonBox(width: 48, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Recent transactions header skeleton
                ShimmerEffect(
                  child: SkeletonBox(width: 160, height: 20, borderRadius: 4),
                ),
                const SizedBox(height: 16),
                // Transaction list skeleton
                const TransactionListSkeleton(itemCount: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
