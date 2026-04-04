// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';

// Base shimmer box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A3E) : AppColors.shimmerBase,
      highlightColor:
          isDark ? const Color(0xFF3A3A5E) : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Comment card skeleton
class CommentCardShimmer extends StatelessWidget {
  const CommentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 60, height: 18, borderRadius: 6),
                const Spacer(),
                ShimmerBox(width: 80, height: 14, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            ShimmerBox(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            ShimmerBox(width: 160, height: 14),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  child:
                      const ShimmerBox(width: 48, height: 28, borderRadius: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// List of comment shimmer cards
class BoardShimmer extends StatelessWidget {
  final int count;
  const BoardShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) => const CommentCardShimmer(),
    );
  }
}

// Search result tile skeleton
class SearchResultShimmer extends StatelessWidget {
  const SearchResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14),
                const SizedBox(height: 6),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// List of search shimmer tiles
class SearchShimmer extends StatelessWidget {
  final int count;
  const SearchShimmer({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, __) => const SearchResultShimmer(),
    );
  }
}

// Favorite profile tile skeleton
class FavoriteProfileTileShimmer extends StatelessWidget {
  const FavoriteProfileTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ShimmerBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 130, height: 14),
                const SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// List of favorite shimmer tiles
class FavoritesShimmer extends StatelessWidget {
  final int count;
  const FavoritesShimmer({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, __) => const FavoriteProfileTileShimmer(),
    );
  }
}

// Profile header skeleton
class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: ShimmerBox(width: 88, height: 88, borderRadius: 44)),
          const SizedBox(height: 16),
          const Center(child: ShimmerBox(width: 140, height: 20)),
          const SizedBox(height: 8),
          const Center(child: ShimmerBox(width: 100, height: 16)),
          const SizedBox(height: 10),
          const Center(child: ShimmerBox(width: 200, height: 14)),
          const SizedBox(height: 6),
          const Center(child: ShimmerBox(width: 160, height: 14)),
          const SizedBox(height: 20),
          const ShimmerBox(width: 120, height: 14, borderRadius: 6),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              5,
              (_) => const ShimmerBox(width: 56, height: 36, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }
}
