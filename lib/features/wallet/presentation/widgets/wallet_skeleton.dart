import 'package:flutter/material.dart';

class WalletSkeleton extends StatefulWidget {
  const WalletSkeleton({super.key});

  @override
  State<WalletSkeleton> createState() => _WalletSkeletonState();
}

class _WalletSkeletonState extends State<WalletSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({required double width, required double height, double borderRadius = 8}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card Skeleton
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D6548).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(width: 120, height: 16),
                  _shimmerBox(width: 110, height: 24, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(width: 160, height: 36),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _shimmerBox(width: double.infinity, height: 60, borderRadius: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(width: double.infinity, height: 60, borderRadius: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _shimmerBox(width: double.infinity, height: 48, borderRadius: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(width: double.infinity, height: 48, borderRadius: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _shimmerBox(width: 160, height: 20),
        const SizedBox(height: 16),
        // Transactions List Skeleton
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _shimmerBox(width: 44, height: 44, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(width: 140, height: 16),
                        const SizedBox(height: 6),
                        _shimmerBox(width: 90, height: 12),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _shimmerBox(width: 60, height: 16),
                      const SizedBox(height: 6),
                      _shimmerBox(width: 50, height: 14, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
