import 'package:flutter/material.dart';

import 'game/game_screen.dart';
import 'monetization/admob_gateway.dart';
import 'monetization/billing.dart';

Future<void> main() async {
  // Required before touching platform channels (MobileAds, billing) ahead of
  // the first frame.
  WidgetsFlutterBinding.ensureInitialized();

  final ads = AdMobGateway();
  await ads.ensureInitialized();

  final billing = Billing();
  await billing.init();

  runApp(UnwindApp(ads: ads, billing: billing));
}

class UnwindApp extends StatelessWidget {
  const UnwindApp({super.key, required this.ads, required this.billing});

  /// The app-lifetime ad gateway, initialised before the first frame.
  final AdMobGateway ads;

  /// Google Play Billing for the one-off "Remove Ads + themes" purchase.
  final Billing billing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unwind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6F5B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Rebuild the game whenever the premium entitlement changes, so ads stop
      // the instant the purchase (or a restore) completes.
      home: ValueListenableBuilder<bool>(
        valueListenable: billing.premium,
        builder: (context, adsRemoved, _) {
          return GameScreen(
            ads: ads,
            adsRemoved: adsRemoved,
            onRemoveAds: adsRemoved ? null : billing.buyPremium,
            onRestore: billing.restore,
          );
        },
      ),
    );
  }
}
