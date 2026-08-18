import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_bottom_sheet.dart';
import 'package:moonjoin/common/widgets/moonjoin/organic_module_icon.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Module Scope Sheet — "Search in… / Recent / All Modules".
///
/// Presentation only: returns the chosen [ModuleModel] via [onSelected]; the
/// caller sets the SEARCH SCOPE only and must NOT call `setModule()` (Application
/// Context stays untouched). Reuses `MoonjoinBottomSheet` + `OrganicModuleIcon`
/// + the existing `SplashController.moduleList`. Data-driven so a future
/// "All Modules" scope tile can be added without redesign.
class SearchScopeSheet {
  static Future<void> show(
    BuildContext context, {
    ModuleModel? recent,
    required void Function(ModuleModel module) onSelected,
  }) {
    final List<ModuleModel> modules = Get.find<SplashController>().moduleList ?? [];
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoonjoinBottomSheet(
        title: 'search_in'.tr,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (recent != null) ...[
            Text('recent'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _RecentTile(module: recent, onSelected: onSelected),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],

          Text('all_modules'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 6 : 4,
              mainAxisSpacing: Dimensions.paddingSizeDefault,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              childAspectRatio: 0.78,
            ),
            itemCount: modules.length,
            itemBuilder: (_, i) => _ModuleGridItem(module: modules[i], onSelected: onSelected),
          ),
        ]),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final ModuleModel module;
  final void Function(ModuleModel) onSelected;
  const _RecentTile({required this.module, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () { Get.back(); onSelected(module); },
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          OrganicModuleIcon(imageUrl: module.iconFullUrl, size: 44, shapeIndex: (module.id ?? 0) % 6),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(module.moduleName ?? '', style: robotoMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
        ]),
      ),
    );
  }
}

class _ModuleGridItem extends StatelessWidget {
  final ModuleModel module;
  final void Function(ModuleModel) onSelected;
  const _ModuleGridItem({required this.module, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () { Get.back(); onSelected(module); },
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        OrganicModuleIcon(imageUrl: module.iconFullUrl, size: 52, shapeIndex: (module.id ?? 0) % 6),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          module.moduleName ?? '',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
