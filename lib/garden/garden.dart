/// Pure growth model for the zen garden meta.
///
/// The garden is the second thing always easing toward completion (the board
/// is the first). Every solved level nudges the current plant one step; once a
/// plant reaches full bloom it joins the garden as a mature plant and a fresh
/// seed begins. This is a pure function of the number of levels solved, so it
/// holds no Flutter/plugin types and is fully unit-tested.
library;

/// Number of solved levels it takes to grow one plant from seed to bloom.
const int kStepsPerPlant = 5;

/// The visible growth stages of the plant currently being grown.
///
/// Ordered from just-planted to fully open, so `.index` doubles as a 0-based
/// progress step within the current plant.
enum GrowthStage {
  seed,
  sprout,
  growing,
  budding,
  bloom,
}

/// A snapshot of the garden derived purely from [levelsSolved].
class GardenState {
  const GardenState({
    required this.levelsSolved,
    this.stepsPerPlant = kStepsPerPlant,
  })  : assert(levelsSolved >= 0, 'levels solved cannot be negative'),
        assert(stepsPerPlant > 0, 'a plant needs at least one step');

  /// Total levels the player has ever solved.
  final int levelsSolved;

  /// How many solves grow one plant to bloom.
  final int stepsPerPlant;

  /// Plants that have reached full bloom and now stand in the garden.
  int get maturePlants => levelsSolved ~/ stepsPerPlant;

  /// Progress of the plant currently growing, as a step in `0..stepsPerPlant-1`.
  int get currentStep => levelsSolved % stepsPerPlant;

  /// The current plant's growth as a fraction in `[0, 1)`.
  double get currentGrowth => currentStep / stepsPerPlant;

  /// The named stage of the plant currently growing.
  GrowthStage get currentStage {
    // Map the current step across the five stages regardless of stepsPerPlant,
    // so the stage still reads naturally if the pacing is ever retuned.
    final stageCount = GrowthStage.values.length;
    final i = (currentStep * stageCount) ~/ stepsPerPlant;
    // currentStep is always >= 0, so only the upper bound needs guarding.
    return GrowthStage.values[i >= stageCount ? stageCount - 1 : i];
  }

  /// The state after solving one more level.
  GardenState grown() =>
      GardenState(levelsSolved: levelsSolved + 1, stepsPerPlant: stepsPerPlant);
}
