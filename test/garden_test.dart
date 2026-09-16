import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/garden/garden.dart';

void main() {
  group('GardenState growth', () {
    test('a fresh garden has nothing grown', () {
      const g = GardenState(levelsSolved: 0);
      expect(g.maturePlants, 0);
      expect(g.currentStep, 0);
      expect(g.currentStage, GrowthStage.seed);
      expect(g.currentGrowth, 0.0);
    });

    test('one plant matures every stepsPerPlant solves', () {
      expect(const GardenState(levelsSolved: 4).maturePlants, 0);
      expect(const GardenState(levelsSolved: 5).maturePlants, 1);
      expect(const GardenState(levelsSolved: 12).maturePlants, 2);
    });

    test('current step cycles within the plant being grown', () {
      expect(const GardenState(levelsSolved: 5).currentStep, 0);
      expect(const GardenState(levelsSolved: 7).currentStep, 2);
      expect(const GardenState(levelsSolved: 9).currentStep, 4);
    });

    test('stage advances from seed to bloom across a plant', () {
      GrowthStage stageAt(int solved) =>
          GardenState(levelsSolved: solved).currentStage;
      expect(stageAt(0), GrowthStage.seed);
      expect(stageAt(4), GrowthStage.bloom);
      // Wraps back to a new seed once the plant matures.
      expect(stageAt(5), GrowthStage.seed);
    });

    test('grown() advances by exactly one solve', () {
      const g = GardenState(levelsSolved: 3);
      expect(g.grown().levelsSolved, 4);
      expect(g.grown().stepsPerPlant, g.stepsPerPlant);
    });

    test('currentGrowth stays within [0, 1)', () {
      for (var solved = 0; solved < 40; solved++) {
        final growth = GardenState(levelsSolved: solved).currentGrowth;
        expect(growth, greaterThanOrEqualTo(0.0));
        expect(growth, lessThan(1.0));
      }
    });
  });
}
