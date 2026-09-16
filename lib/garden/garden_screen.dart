import 'package:flutter/material.dart';

import '../monetization/billing.dart';
import 'garden_controller.dart';
import 'garden_theme.dart';
import 'garden_view.dart';

/// The full garden screen: the growing garden above, a theme picker below.
/// Premium themes show a lock; tapping one starts the purchase. Everything
/// reacts to premium and garden changes, so a purchase or a new bloom updates
/// the screen without navigating away.
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key, required this.garden, required this.billing});

  final GardenController garden;
  final Billing billing;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([billing.premium, garden]),
      builder: (context, _) {
        final premium = billing.premium.value;
        final theme = garden.themeFor(premium: premium);
        return Scaffold(
          backgroundColor: theme.sky,
          body: SafeArea(
            child: Column(
              children: [
                _Header(plants: garden.state.maturePlants, theme: theme),
                Expanded(
                  child: GardenView(state: garden.state, theme: theme),
                ),
                _ThemePicker(
                  garden: garden,
                  premium: premium,
                  onBuyPremium: billing.buyPremium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plants, required this.theme});

  final int plants;
  final GardenTheme theme;

  @override
  Widget build(BuildContext context) {
    final grown = plants == 1 ? '1 plant grown' : '$plants plants grown';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.leaf),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Your garden',
              style: TextStyle(
                color: theme.leaf,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(grown, style: TextStyle(color: theme.stem, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({
    required this.garden,
    required this.premium,
    required this.onBuyPremium,
  });

  final GardenController garden;
  final bool premium;
  final Future<void> Function() onBuyPremium;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: kGardenThemes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final t = kGardenThemes[i];
          final unlocked = isThemeUnlocked(t.id, premium: premium);
          final selected = garden.selectedThemeId == t.id && unlocked;
          return _ThemeChip(
            theme: t,
            locked: !unlocked,
            selected: selected,
            onTap: () {
              if (unlocked) {
                garden.selectTheme(t.id, premium: premium);
              } else {
                onBuyPremium();
              }
            },
          );
        },
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final GardenTheme theme;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.sky, theme.soil],
                ),
                border: Border.all(
                  color: selected ? theme.bloom : const Color(0x33FFFFFF),
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // A tiny bloom-on-stem sample of the palette.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.bloom,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(width: 3, height: 20, color: theme.stem),
                      ],
                    ),
                  ),
                  if (locked)
                    const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x66000000)),
                      child: SizedBox.expand(
                        child: Icon(Icons.lock, color: Colors.white70, size: 22),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? theme.bloom : theme.leaf,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
