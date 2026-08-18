import 'package:flutter/material.dart';
import 'package:moonjoin/features/parcel/controllers/parcel_controller.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// "Easiest way to get services" — a numbered step flow (matching the Parcel
/// design) built from the backend `videoContentDetails.bannerContents` (even
/// entries = step title, odd entries = step description). Presentation only; the
/// backend content is wrapped by the design, never replaced.
class ServiceInfoListWidget extends StatelessWidget {
  final ParcelController parcelController;
  const ServiceInfoListWidget({super.key, required this.parcelController});

  @override
  Widget build(BuildContext context) {
    if (parcelController.videoContentDetails == null) return const SizedBox();

    final List<String> title = [];
    final List<String> subTitle = [];
    final contents = parcelController.videoContentDetails!.bannerContents ?? [];
    for (int i = 0; i < contents.length; i++) {
      if (i % 2 == 0) {
        title.add(contents[i].value ?? '');
      } else {
        subTitle.add(contents[i].value ?? '');
      }
    }
    if (title.isEmpty) return const SizedBox();

    final Color green = Theme.of(context).primaryColor;
    final int count = title.length;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(count, (i) {
      return Expanded(
        child: Column(children: [

          // Numbered circle + connecting dotted line to neighbours
          Row(children: [
            Expanded(child: i == 0 ? const SizedBox() : _dottedLine(context)),
            Container(
              height: 28, width: 28, alignment: Alignment.center,
              decoration: BoxDecoration(color: green, shape: BoxShape.circle),
              child: Text('${i + 1}', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
            ),
            Expanded(child: i == count - 1 ? const SizedBox() : _dottedLine(context)),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              title[i], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: robotoBold.copyWith(color: green, fontSize: Dimensions.fontSizeSmall),
            ),
          ),
          const SizedBox(height: 2),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              i < subTitle.length ? subTitle[i] : '',
              maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall),
            ),
          ),
        ]),
      );
    }));
  }

  Widget _dottedLine(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final int dashCount = (constraints.maxWidth / 7).floor().clamp(0, 40);
      return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(dashCount, (_) {
        return Container(width: 3, height: 1.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.5));
      }));
    });
  }
}
