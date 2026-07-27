import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — the single authentication shell for
/// BOTH hosts. Presentation only.
///
/// Ownership contract:
///  - AuthScaffold owns: responsive body layout, dialog-safe spacing, and
///    rendering of the close/back affordance.
///  - The host (SignInScreen / AuthDialogWidget) owns: the Flutter `Dialog`,
///    barrier + dismissal behavior, desktop positioning, and any navigation.
///
/// Therefore AuthScaffold NEVER creates `Dialog()`, never controls
/// `barrierDismissible`, and never calls `Navigator`/`Get.back()`. The back /
/// close affordance only invokes the `onBack` callback it is given.
///
/// Premium layout: when a [hero] is supplied, it renders full-bleed at the top
/// (edge-to-edge green with curved bottom) and the [child] card floats up to
/// slightly overlap it. When a [header] is supplied instead, it composes
/// `header → body` (no Material AppBar).
class AuthScaffold extends StatelessWidget {
  final Widget child;

  /// Optional premium brand hero (typically [AuthHero]). Mutually exclusive with [header].
  final Widget? hero;

  /// Optional titled header (typically [AuthHeader]). Mutually exclusive with [hero].
  final Widget? header;

  /// Show the back/close affordance. When false, no affordance is rendered.
  final bool showBack;

  /// Invoked when the affordance is tapped. Host owns the actual navigation.
  final VoidCallback? onBack;

  /// Dialog-host mode: returns the body column only (no Scaffold), with a
  /// top-right close affordance. The host wraps this in its own `Dialog`.
  final bool isDialog;

  final double maxWidth;
  final bool scrollable;

  /// How far the floating card overlaps the hero.
  final double heroOverlap;

  const AuthScaffold({
    super.key,
    required this.child,
    this.hero,
    this.header,
    this.showBack = true,
    this.onBack,
    this.isDialog = false,
    this.maxWidth = 500,
    this.scrollable = true,
    this.heroOverlap = 36,
  }) : assert(hero == null || header == null, 'Provide either hero or header, not both.');

  @override
  Widget build(BuildContext context) {
    if (isDialog) return _dialogBody(context);

    if (hero != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _heroLayout(context),
      );
    }

    if (header != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          child: Column(children: [
            header!,
            Expanded(
              child: _maybeScroll(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraLarge,
                    vertical: Dimensions.paddingSizeExtraLarge,
                  ),
                  child: _constrained(context, child),
                ),
              ),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: showBack
          ? AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
              leading: IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
              actions: const [SizedBox()],
            )
          : null,
      body: SafeArea(
        child: _maybeScroll(
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
              child: _constrained(context, child),
            ),
          ),
        ),
      ),
    );
  }

  // Full-bleed hero + floating overlapping card.
  Widget _heroLayout(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return _maybeScroll(
      Column(children: [
        Stack(children: [
          hero!,
          if (showBack)
            Positioned(
              top: topInset + 2,
              left: Dimensions.paddingSizeSmall,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              ),
            ),
        ]),
        Transform.translate(
          offset: Offset(0, -heroOverlap),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              0,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
            ),
            child: _constrained(context, child),
          ),
        ),
      ]),
    );
  }

  // Dialog-host mode: body only + close affordance; host owns the Dialog.
  Widget _dialogBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBack)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(onPressed: onBack, icon: const Icon(Icons.clear)),
          ),
        ?header,
        ?hero,
        Flexible(
          child: _maybeScroll(
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeExtraLarge,
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeExtraLarge,
                Dimensions.paddingSizeLarge,
              ),
              child: _constrained(context, child),
            ),
          ),
        ),
      ],
    );
  }

  Widget _maybeScroll(Widget body) {
    return scrollable
        ? SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: body)
        : body;
  }

  Widget _constrained(BuildContext context, Widget body) {
    final bool wide = ResponsiveHelper.isDesktop(context) || MediaQuery.of(context).size.width > 700;
    return Center(
      child: SizedBox(width: wide ? maxWidth : double.infinity, child: body),
    );
  }
}
