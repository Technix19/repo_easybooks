import 'package:flutter_test/flutter_test.dart';
import 'package:repo_easybooks/formula.dart';

void main() {
  final formula = Formula();

  group('EasyBooks bookkeeping formulas', () {
    test('calculates total sales, COGS, and gross profit', () {
      expect(formula.getTotalGrossSales(10, 112.0), 1120.0);
      expect(formula.getTotalCOGs(10, 50.0), 500.0);
      expect(formula.getComputedGrossProfit(10, 112.0, 50.0), 620.0);
    });

    test('calculates VAT extracted from tax-inclusive amounts', () {
      expect(formula.getOutputVAT(1, 112.0), closeTo(12.0, 1e-9));
      expect(formula.getInputVAT(112.0), closeTo(12.0, 1e-9));
      expect(formula.getTotalExpensesMinusVAT(112.0, 12.0), 100.0);
    });

    test('calculates expense totals', () {
      expect(formula.getTotalExpenses(4.0, 250.0), 1000.0);
    });
  });
}
