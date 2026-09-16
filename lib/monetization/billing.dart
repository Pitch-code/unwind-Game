import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entitlement.dart';

/// Wraps Google Play Billing (via in_app_purchase) for the single
/// "Remove Ads + unlock all garden themes" non-consumable purchase.
///
/// The premium flag is cached locally so it survives restarts without a
/// network round-trip; [restore] and the purchase stream keep it truthful.
/// Every method is defensive — a failure here must never crash the game or
/// leave the UI stuck, so problems resolve to "not premium" rather than throw.
///
/// The pure decision of whether an outcome unlocks premium lives in
/// [grantsPremium]; this class only translates plugin types and persists.
class Billing {
  Billing({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  static const String _prefsKey = 'unwind_premium_owned';

  final InAppPurchase _iap;

  /// Reactive premium state. The UI listens to this to hide ads and reveal
  /// the themes without needing to be rebuilt manually.
  final ValueNotifier<bool> premium = ValueNotifier<bool>(false);

  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  /// Whether the store connection is usable on this device/build.
  bool get isStoreAvailable => _storeAvailable;
  bool _storeAvailable = false;

  /// The localised price string (e.g. "$3.99"), once the product is known.
  String? get price => _product?.price;

  /// Loads the cached entitlement, connects to the store, and begins listening
  /// for purchase updates. Safe to call once at startup; never throws.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    premium.value = prefs.getBool(_prefsKey) ?? false;

    _storeAvailable = await _safe(() => _iap.isAvailable(), orElse: false);
    if (!_storeAvailable) return;

    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});

    await _loadProduct();
  }

  Future<void> _loadProduct() async {
    final response = await _safe<ProductDetailsResponse?>(
      () => _iap.queryProductDetails({kPremiumProductId}),
      orElse: null,
    );
    final details = response?.productDetails ?? const <ProductDetails>[];
    if (details.isNotEmpty) {
      _product = details.first;
    }
  }

  /// Launches the purchase flow. Results arrive asynchronously on the stream.
  Future<void> buyPremium() async {
    if (premium.value) return; // already owned
    if (_product == null) {
      // Product not loaded yet (slow store, or not configured). Try once more.
      await _loadProduct();
    }
    final product = _product;
    if (product == null) return;

    final param = PurchaseParam(productDetails: product);
    await _run(() async {
      await _iap.buyNonConsumable(purchaseParam: param);
    });
  }

  /// Re-grants a previously bought entitlement (new device / reinstall).
  Future<void> restore() async {
    await _run(() => _iap.restorePurchases());
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != kPremiumProductId) continue;

      final outcome = _outcomeOf(purchase.status);
      if (grantsPremium(outcome)) {
        await _grant();
      }

      // The store requires acknowledging finished purchases, else it refunds.
      if (purchase.pendingCompletePurchase) {
        await _run(() => _iap.completePurchase(purchase));
      }
    }
  }

  PurchaseOutcome _outcomeOf(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.purchased:
        return PurchaseOutcome.purchased;
      case PurchaseStatus.restored:
        return PurchaseOutcome.restored;
      case PurchaseStatus.pending:
        return PurchaseOutcome.pending;
      case PurchaseStatus.error:
        return PurchaseOutcome.error;
      case PurchaseStatus.canceled:
        return PurchaseOutcome.canceled;
    }
  }

  Future<void> _grant() async {
    if (premium.value) return;
    premium.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Runs a value-returning [action], swallowing any error and returning
  /// [orElse] instead, so a billing hiccup can't reach the game loop.
  Future<T> _safe<T>(Future<T> Function() action, {required T orElse}) async {
    try {
      return await action();
    } catch (_) {
      return orElse;
    }
  }

  /// Runs a fire-and-forget [action], swallowing any error.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    premium.dispose();
  }
}
