import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:moonjoin/features/html/controllers/html_controller.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/html_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/common/widgets/web_page_title_widget.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HtmlViewerScreen extends StatefulWidget {
  final HtmlType htmlType;
  const HtmlViewerScreen({super.key, required this.htmlType});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {

  @override
  void initState() {
    super.initState();

    Get.find<HtmlController>().getHtmlText(widget.htmlType);
  }

  // Single title mapping reused by header + web title (unchanged semantics).
  String get _title {
    switch(widget.htmlType) {
      case HtmlType.termsAndCondition: return 'terms_conditions'.tr;
      case HtmlType.aboutUs: return 'about_us'.tr;
      case HtmlType.privacyPolicy: return 'privacy_policy'.tr;
      case HtmlType.shippingPolicy: return 'shipping_policy'.tr;
      case HtmlType.refund: return 'refund_policy'.tr;
      case HtmlType.cancellation: return 'cancellation_policy'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isDesktop ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: Column(children: [

        if(!isDesktop) ProfilePageHeader(title: _title),

        Expanded(child: GetBuilder<HtmlController>(builder: (htmlController) {
          if(htmlController.htmlText == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if(htmlController.htmlText!.trim().isEmpty) {
            return Center(child: NoDataScreen(text: 'no_data_found'.tr, showFooter: true));
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              WebScreenTitleWidget(title: _title),

              FooterView(child: Center(child: Container(
                width: Dimensions.webMaxWidth,
                margin: EdgeInsets.all(isDesktop ? 0 : Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: HtmlWidget(
                  htmlController.htmlText ?? '',
                  key: Key(widget.htmlType.toString()),
                  textStyle: robotoRegular.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.75),
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  onTapUrl: (String url) {
                    return launchUrlString(url);
                  },
                ),
              ))),
            ]),
          );
        })),

      ]),
    );
  }
}
