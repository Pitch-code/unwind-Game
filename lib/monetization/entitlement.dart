/// Pure entitlement logic for the single "Remove Ads + unlock themes" purchase.
///
/// This holds no plugin types so it can be unit-tested without a device. The
/// billing layer translates the platform's purchase status into a
/// [PurchaseOutcome], and [grantsPremium] decides whether that outcome should
/// unlock premium.
library;

/// The product id configured in Google Play Console for the one-off unlock.
const String kPremiumProductId = 'unwind_premium';

/// The normalised result of a purchase or restore attempt, independent of the
/// underlying billing plugin's own status enum.
enum PurchaseOutcome {
  /// A fresh purchase completed successfully.
  purchased,

  /// A previously owned entitlement was restored (e.g. reinstall, new device).
  restored,

  /// The purchase is awaiting completion (e.g. pending parental approval).
  pending,

  /// The purchase failed with an error.
  error,

  /// The user dismissed the purchase flow without buying.
  canceled,
}

/// Whether an outcome should unlock premium (remove ads + unlock themes).
///
/// Only a completed purchase or a restore grants premium. Pending, error and
/// canceled outcomes leave the player un-upgraded — pending in particular must
/// NOT unlock until it later resolves to [PurchaseOutcome.purchased].
bool grantsPremium(PurchaseOutcome outcome) {
  switch (outcome) {
    case PurchaseOutcome.purchased:
    case PurchaseOutcome.restored:
      return true;
    case PurchaseOutcome.pending:
    case PurchaseOutcome.error:
    case PurchaseOutcome.canceled:
      return false;
  }
}
