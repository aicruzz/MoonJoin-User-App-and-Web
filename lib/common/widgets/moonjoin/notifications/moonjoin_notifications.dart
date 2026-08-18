import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/confirmation_dialog.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_components.dart';
import 'package:moonjoin/util/dimensions.dart';

/// # MoonJoin Notification System — platform façade (Phase A1)
///
/// A **thin orchestration layer** over the existing, frozen MoonJoin
/// notification primitives. It creates **no new UI**: every method delegates to
/// a component that already exists in `common/widgets/` — `SuccessBanner`,
/// `MoonjoinDialog`, `ConfirmationDialog(moonjoin: true)`, `MoonjoinBottomSheet`,
/// `InformationCard`, `StatusBadge`, `MoonjoinErrorState`, `MoonjoinEmptyState`,
/// and `showCustomSnackBar`. Those components remain the single source of truth
/// for how a notification looks.
///
/// ## Why this exists
/// So every current and future MoonJoin surface — customer, vendor, delivery,
/// admin, and **future AI messages** — resolves to **one** notification
/// language instead of inventing another dialog / sheet / banner / toast. If a
/// feature needs to tell the user something, it calls this façade; it never
/// builds a bespoke popup.
///
/// ## Business-logic boundary
/// Pure presentation. This façade holds no state, calls no API, and touches no
/// controller / repository / service. All behaviour is wired in through the
/// caller's callbacks. It must never be given business logic.
///
/// See `docs/MOONJOIN_NOTIFICATION_SYSTEM.md` for the taxonomy and reuse rules.
class MoonJoinNotifications {
  MoonJoinNotifications._();

  // ---------------------------------------------------------------------------
  // 1. SUCCESS  → SuccessBanner (order placed, payment successful, account made)
  // ---------------------------------------------------------------------------

  /// Modal success confirmation. Wraps the frozen [SuccessBanner] in a dialog.
  /// Use for terminal positive outcomes (order placed, payment successful).
  static Future<T?> success<T>({
    required String title,
    String? message,
    String? assetImage,
    String? actionText,
    VoidCallback? onAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      Dialog(
        backgroundColor: Theme.of(Get.context!).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
        child: SuccessBanner(
          title: title,
          message: message,
          assetImage: assetImage,
          actionText: actionText,
          onAction: onAction,
          secondaryActionText: secondaryActionText,
          onSecondaryAction: onSecondaryAction,
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Inline success/status block (not modal) — the same [SuccessBanner] for
  /// embedding inside a screen (e.g. an order-success page body).
  static Widget successBlock({
    required String title,
    String? message,
    String? assetImage,
    String? actionText,
    VoidCallback? onAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    return SuccessBanner(
      title: title,
      message: message,
      assetImage: assetImage,
      actionText: actionText,
      onAction: onAction,
      secondaryActionText: secondaryActionText,
      onSecondaryAction: onSecondaryAction,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. INFORMATION  → InformationCard / StatusBadge (order updates, progress)
  // ---------------------------------------------------------------------------

  /// Inline notice card (icon · title · subtitle · optional action). Soft amber
  /// tint by default — the same [InformationCard] used by the frozen Home
  /// "Some items are unavailable · Review Items" banner. Embed it in a layout.
  static Widget infoCard({
    required String title,
    String? subtitle,
    IconData icon = Icons.info_outline,
    Color? accentColor,
    String? actionText,
    VoidCallback? onAction,
    Widget? leading,
  }) {
    return InformationCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      actionText: actionText,
      onAction: onAction,
      leading: leading,
    );
  }

  /// Small status pill — the same [StatusBadge] used for order status / tags.
  static Widget statusBadge({
    required String text,
    Color? color,
    bool filled = false,
    IconData? icon,
  }) {
    return StatusBadge(text: text, color: color, filled: filled, icon: icon);
  }

  // ---------------------------------------------------------------------------
  // 3. WARNING  → MoonjoinBottomSheet + InformationCard (attention required)
  // ---------------------------------------------------------------------------

  /// Attention-required bottom sheet. Composes the frozen [MoonjoinBottomSheet]
  /// with an [InformationCard] and optional action buttons ([MoonjoinButton]).
  /// Use when the user must notice something and may act (not for terminal
  /// errors — use [error] — and not to rebuild any already-frozen flow).
  static Future<T?> warningSheet<T>({
    required String title,
    required String message,
    String? sheetTitle,
    IconData icon = Icons.warning_amber_rounded,
    Color? accentColor,
    List<MoonJoinNotificationAction> actions = const [],
    bool isDismissible = true,
  }) {
    final Color accent = accentColor ?? const Color(0xFFE8A100);
    return Get.bottomSheet<T>(
      MoonjoinBottomSheet(
        title: sheetTitle,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InformationCard(title: title, subtitle: message, icon: icon, accentColor: accent),
          if (actions.isNotEmpty) const SizedBox(height: Dimensions.paddingSizeDefault),
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: Dimensions.paddingSizeSmall),
            MoonjoinButton(
              text: actions[i].label,
              type: actions[i].isPrimary ? MoonjoinButtonType.primary : MoonjoinButtonType.outline,
              onPressed: actions[i].onPressed,
            ),
          ],
        ]),
      ),
      isScrollControlled: true,
      isDismissible: isDismissible,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ERROR  → MoonjoinDialog / ConfirmationDialog (payment/order failed)
  // ---------------------------------------------------------------------------

  /// Terminal error dialog. Wraps the frozen [MoonjoinDialog] with an error
  /// accent. Use for payment failed / order failed and similar hard failures.
  static Future<T?> error<T>({
    required String title,
    String? message,
    IconData icon = Icons.error_outline,
    String? confirmText,
    VoidCallback? onConfirm,
    String? cancelText,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      MoonjoinDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: Theme.of(Get.context!).colorScheme.error,
        confirmText: confirmText,
        onConfirm: onConfirm,
        cancelText: cancelText,
        onCancel: onCancel,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Yes/No confirmation — the frozen [ConfirmationDialog] MoonJoin variant.
  /// [iconImage] is an image asset path (e.g. `Images.support`), matching the
  /// existing component. Use for destructive/irreversible confirmations.
  static Future<T?> confirm<T>({
    required String iconImage,
    required String description,
    required VoidCallback onYesPressed,
    String? title,
    VoidCallback? onNoPressed,
    bool isLogOut = false,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      ConfirmationDialog(
        icon: iconImage,
        title: title,
        description: description,
        onYesPressed: onYesPressed,
        onNoPressed: onNoPressed,
        isLogOut: isLogOut,
        moonjoin: true,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TRANSIENT FEEDBACK  → showCustomSnackBar ONLY (saved, updated, minor)
  // ---------------------------------------------------------------------------

  /// The one and only MoonJoin toast. Delegates to the app-wide
  /// [showCustomSnackBar]. Never build another toast/snackbar system.
  static void transient(
    String? message, {
    bool isError = false,
    bool getXSnackBar = false,
    int? duration,
  }) {
    showCustomSnackBar(message, isError: isError, getXSnackBar: getXSnackBar, showDuration: duration);
  }

  // ---------------------------------------------------------------------------
  // PAGE-LEVEL STATES  → MoonjoinErrorState / MoonjoinEmptyState (inline)
  // ---------------------------------------------------------------------------

  /// Full-area error placeholder with retry — the frozen [MoonjoinErrorState].
  /// For failed loads / no-connection screens (a page state, not a popup).
  static Widget errorState({
    String? title,
    String? message,
    String? assetImage,
    IconData icon = Icons.error_outline,
    String? retryText,
    VoidCallback? onRetry,
  }) {
    return MoonjoinErrorState(
      title: title ?? 'sorry_something_went_wrong'.tr,
      message: message,
      assetImage: assetImage,
      icon: icon,
      retryText: retryText ?? 'try_again'.tr,
      onRetry: onRetry,
    );
  }

  /// Full-area empty placeholder — the frozen [MoonjoinEmptyState].
  static Widget emptyState({
    required String title,
    String? message,
    String? assetImage,
    IconData icon = Icons.inbox_outlined,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return MoonjoinEmptyState(
      title: title,
      message: message,
      assetImage: assetImage,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
    );
  }
}

/// A single action inside a [MoonJoinNotifications.warningSheet]. Data holder
/// only — no UI. [isPrimary] draws a filled MoonJoin button; otherwise outline.
class MoonJoinNotificationAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const MoonJoinNotificationAction({required this.label, this.onPressed, this.isPrimary = false});
}
