class Formula {
  double getComputedGrossProfit(
    quantity,
    selling_price_per_unit,
    cogs_per_unit,
  ) {
    return (quantity * selling_price_per_unit) - (quantity * cogs_per_unit);
  }

  double getTotalCOGs(quantity, cogs_per_unit) {
    return quantity * cogs_per_unit;
  }

  double getOutputVAT(quantity, selling_price_per_unit) {
    return (quantity * selling_price_per_unit) * (12 / 112);
  }

  double getTotalGrossSales(quantity, selling_price_per_unit) {
    return selling_price_per_unit * quantity;
  }

  double getTotalExpenses(amount_of_units, price_per_unit) {
    return amount_of_units * price_per_unit;
  }

  double getInputVAT(total_expenses) {
    return total_expenses * (12 / 112);
  }

  double getTotalExpensesMinusVAT(total_expenses, input_vat) {
    return total_expenses - input_vat;
  }
}
