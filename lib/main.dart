import 'package:flutter/material.dart';

import 'game/game_screen.dart';
import 'monetization/admob_gateway.dart';

Future<void> main() async {
  // Required before touching platform channels (MobileAds) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final ads = AdMobGateway();
  await ads.ensureInitialized();

  runApp(UnwindApp(ads: ads));
}

class UnwindApp extends StatelessWidget {
  const UnwindApp({super.key, required this.ads});

  /// The app-lifetime ad gateway, initialised before the first frame.
  final AdMobGateway ads;

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
      home: GameScreen(ads: ads),
    );
  }
}
