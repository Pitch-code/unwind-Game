import 'package:flutter/material.dart';

import 'game/game_screen.dart';
import 'garden/garden_controller.dart';
import 'garden/garden_screen.dart';
import 'monetization/admob_gateway.dart';
import 'monetization/billing.dart';

Future<void> main() async {
  // Required before touching platform channels (MobileAds, billing, prefs)
  // ahead of the first frame.
  WidgetsFlutterBinding.ensureInitialized();

  final ads = AdMobGateway();
  await ads.ensureInitialized();

  final billing = Billing();
  await billing.init();

  final garden = GardenController();
  await garden.init();

  runApp(UnwindApp(ads: ads, billing: billing, garden: garden));
}

class UnwindApp extends StatelessWidget {
  const UnwindApp({
    super.key,
    required this.ads,
    required this.billing,
    required this.garden,
  });

  /// The app-lifetime ad gateway, initialised before the first frame.
  final AdMobGateway ads;

  /// Google Play Billing for the one-off "Remove Ads + themes" purchase.
  final Billing billing;

  /// Persisted zen-garden progress and theme selection.
  final GardenController garden;

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
      // Rebuild when either premium (ads on/off, themes unlocked) or the garden
      // (a level was solved) changes, so both stay in sync with no manual push.
      home: ListenableBuilder(
        listenable: Listenable.merge([billing.premium, garden]),
        builder: (context, _) {
          final adsRemoved = billing.premium.value;
          return GameScreen(
            ads: ads,
            adsRemoved: adsRemoved,
            onRemoveAds: adsRemoved ? null : billing.buyPremium,
            onRestore: billing.restore,
            garden: garden.state,
            onLevelSolved: garden.recordSolved,
            onOpenGarden: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GardenScreen(garden: garden, billing: billing),
              ),
            ),
          );
        },
      ),
    );
  }
}
