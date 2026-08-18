import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';

/// A single module/category glyph rendered inside the MoonJoin circular
/// white face with a green ring. Provide exactly one of [imageUrl],
/// [assetImage], [icon] or [child].
class ModuleIcon extends StatelessWidget {
  final String? imageUrl;
  final String? assetImage;
  final IconData? icon;
  final Widget? child;
  final double size;
  final Color? ringColor;

  const ModuleIcon({
    super.key,
    this.imageUrl,
    this.assetImage,
    this.icon,
    this.child,
    this.size = 70,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color ring = ringColor ?? Theme.of(context).primaryColor;
    // Ring thickness and inner padding scale with the tile so featured and
    // normal tiles keep the same proportions as the reference design.
    final double ringWidth = (size * 0.035).clamp(2.5, 5.0);
    final double pad = (size * 0.03).clamp(2.0, 5.0);
    return Container(
      height: size, width: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: ringWidth),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipOval(child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    if (child != null) return child!;
    if (icon != null) return Icon(icon, color: Theme.of(context).primaryColor, size: size * 0.5);
    if (assetImage != null) return Image.asset(assetImage!, fit: BoxFit.cover);
    if (imageUrl != null && imageUrl!.isNotEmpty) return CustomImage(image: imageUrl!, fit: BoxFit.cover);
    return const SizedBox();
  }
}
