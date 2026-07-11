import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// A single shimmering placeholder block. Compose these to build any skeleton
/// layout. Pure presentation.
class SkeletonBox extends StatelessWidget {
  final double? height;
  final double? width;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool circle;

  const SkeletonBox({
    super.key,
    this.height,
    this.width,
    this.radius = Dimensions.radiusSmall,
    this.margin,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width, margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).shadowColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps any [child] tree of [SkeletonBox]es with the shimmer animation.
class MoonjoinSkeleton extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const MoonjoinSkeleton({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer(duration: const Duration(seconds: 2), enabled: enabled, child: child);
  }
}

/// A ready-made list skeleton: [itemCount] shimmering rows (thumbnail + two
/// text lines), matching the MoonJoin list layouts.
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  const SkeletonListLoader({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault)});

  @override
  Widget build(BuildContext context) {
    return MoonjoinSkeleton(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) => Row(children: [
          const SkeletonBox(height: 70, width: 70, radius: Dimensions.radiusDefault),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              SkeletonBox(height: 14, width: 160),
              SizedBox(height: Dimensions.paddingSizeSmall),
              SkeletonBox(height: 12, width: 100),
              SizedBox(height: Dimensions.paddingSizeSmall),
              SkeletonBox(height: 12, width: 60),
            ]),
          ),
        ]),
      ),
    );
  }
}
