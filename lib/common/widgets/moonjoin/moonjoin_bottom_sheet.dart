import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// A styled MoonJoin bottom-sheet container: rounded top corners, a drag
/// handle, an optional title row with close button, and a scrollable [child].
/// Pure presentation — pass it to `showModalBottomSheet` / `Get.bottomSheet`.
class MoonjoinBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  const MoonjoinBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.showClose = false,
    this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (showHandle)
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              height: 4, width: 40,
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
              child: Row(children: [
                Expanded(child: Text(title!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
                if (showClose)
                  InkWell(onTap: () => Navigator.of(context).maybePop(), child: Icon(Icons.close, color: Theme.of(context).hintColor)),
              ]),
            ),
          Flexible(child: SingleChildScrollView(padding: padding, child: child)),
        ]),
      ),
    );
  }
}
