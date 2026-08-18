import 'package:flutter/material.dart';
import 'package:moonjoin/common/models/module_availability.dart';
import 'package:moonjoin/common/widgets/moonjoin/organic_module_icon.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Organic module glyph (green ring) with a label beneath — the MoonJoin home
/// module grid entry. Composes [OrganicModuleIcon] so the per-module blob shape
/// stays consistent. Pass [shapeIndex] to pick the module's stable organic
/// shape. Pure presentation; wire the tap via [onTap].
///
/// [availability] controls the module state: [ModuleAvailability.enabled] is
/// fully interactive; [ModuleAvailability.unavailable] is dimmed + desaturated
/// with tap disabled (no layout shift). ([disabled] modules are omitted upstream
/// and never reach this widget.)
class CategoryTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final String? assetImage;
  final IconData? icon;
  final VoidCallback? onTap;
  final double iconSize;
  final int shapeIndex;
  final double artworkFraction;
  final ModuleAvailability availability;

  const CategoryTile({
    super.key,
    required this.label,
    this.imageUrl,
    this.assetImage,
    this.icon,
    this.onTap,
    this.iconSize = 70,
    this.shapeIndex = 0,
    this.artworkFraction = 0.89,
    this.availability = ModuleAvailability.enabled,
  });

  // Reduce saturation to ~50% without changing size (no layout shift).
  static const ColorFilter _desaturate = ColorFilter.matrix(<double>[
    0.6063, 0.3576, 0.0361, 0, 0,
    0.1063, 0.8576, 0.0361, 0, 0,
    0.1063, 0.3576, 0.5361, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final bool unavailable = availability == ModuleAvailability.unavailable;

    Widget tile = InkWell(
      onTap: unavailable ? null : onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        OrganicModuleIcon(imageUrl: imageUrl, assetImage: assetImage, icon: icon, size: iconSize, shapeIndex: shapeIndex, artworkFraction: artworkFraction),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        SizedBox(
          width: iconSize + 20,
          child: Text(
            label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ),
      ]),
    );

    if (unavailable) {
      // Dimmed + desaturated + non-interactive; identical footprint (no shift).
      tile = IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: ColorFiltered(colorFilter: _desaturate, child: tile),
        ),
      );
    }
    return tile;
  }
}
