import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaxReportNotVatRegisteredPage extends StatefulWidget {
  const TaxReportNotVatRegisteredPage({super.key});

  @override
  State<TaxReportNotVatRegisteredPage> createState() =>
      _TaxReportNotVatRegisteredPageState();
}

class _TaxReportNotVatRegisteredPageState
    extends State<TaxReportNotVatRegisteredPage> {
  final supabase = Supabase.instance.client;
  DateTime? utcStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime? utcEndDate = DateTime.now();

  num total_gross_sales = 0;
  num total_cogs = 0;
  num total_gross_profit = 0;
  num total_expenses = 0;
  num total_expenses_minus_vat = 0;
  num output_vat = 0;
  num input_vat = 0;
  num owed_vat = 0;
  num total_net_profit_before_taxes = 0;
  num total_net_profit_vat_reg = 0;
  num total_net_profit_percentage_tax = 0;

  // --- Typography tokens ---
  static const Color _fg = Colors.white;
  static const Color _fgDim = Colors.white70;

  static const _titleStyle = TextStyle(
    color: _fg,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: .2,
    height: 1.2,
  );
  static const _dateStyle = TextStyle(
    color: _fg,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const _labelStyle = TextStyle(
    color: Color(0xFFBEBEBE),
    fontSize: 20,
    letterSpacing: .15,
    height: 1.25,
  );
  static final _valueStyle = TextStyle(
    color: _fg,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number formatting: Peso with 2 decimals
  static final NumberFormat _nf = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  // ===== fetchers (unchanged logic) =====
  Future<num> fetch_cmptd_total_gross_sales() async {
    final rows = await supabase
        .from('income')
        .select('total_gross_sales')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['total_gross_sales'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_cogs() async {
    final rows = await supabase
        .from('income')
        .select('total_cogs')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['total_cogs'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_gross_profit() async {
    final rows = await supabase
        .from('income')
        .select('computed_gross_profit')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['computed_gross_profit'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_output_vat() async {
    final rows = await supabase
        .from('income')
        .select('output_vat')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['output_vat'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_expenses() async {
    final rows = await supabase
        .from('expense')
        .select('total_expenses')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['total_expenses'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_expenses_minus_vat() async {
    final rows = await supabase
        .from('expense')
        .select('total_expenses_minus_vat')
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['total_expenses_minus_vat'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  Future<num> fetch_cmptd_total_input_vat() async {
    final rows = await supabase
        .from('expense')
        .select('input_vat')
        .eq('is_vat_registered', true)
        .gte('created_at', utcStartDate!.toIso8601String())
        .lt('created_at', utcEndDate!.toIso8601String());
    return (rows as List)
        .map((e) => (e['input_vat'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
  }

  num fetch_cmptd_owed_vat({required num output_vat, required num input_vat}) {
    return owed_vat = output_vat - input_vat;
  }

  num fetch_cmptd_total_net_profit_before_taxes({
    required total_gross_sales,
    required total_expenses,
  }) {
    return total_net_profit_before_taxes = total_gross_sales - total_expenses;
  }

  num fetch_cmptd_total_net_profit_vat_reg({
    required num total_gross_sales,
    required num total_expenses,
    required num owed_vat,
  }) {
    return total_net_profit_vat_reg =
        total_gross_sales - total_expenses - (owed_vat);
  }

  num fetch_cmptd_total_net_profit_percentage_tax({
    required num total_gross_sales,
    required num total_expenses,
  }) {
    return total_net_profit_percentage_tax =
        (total_gross_sales * 0.97) - total_expenses;
  }

  Future<void> _refreshAll() async {
    final tgs = await fetch_cmptd_total_gross_sales();
    final tcogs = await fetch_cmptd_total_cogs();
    final tgross = await fetch_cmptd_total_gross_profit();
    final texp = await fetch_cmptd_total_expenses();
    final texpMinus = await fetch_cmptd_total_expenses_minus_vat();
    final tout = await fetch_cmptd_total_output_vat();
    final tin = await fetch_cmptd_total_input_vat();

    final owed = tout - tin;
    final npBefore = tgs - texp;
    final npVatReg = tgs - texpMinus - owed;
    final npPct = (tgs * 0.97) - texp;

    setState(() {
      total_gross_sales = tgs;
      total_cogs = tcogs;
      total_gross_profit = tgross;
      total_expenses = texp;
      total_expenses_minus_vat = texpMinus;
      output_vat = tout;
      input_vat = tin;
      owed_vat = owed;
      total_net_profit_before_taxes = npBefore;
      total_net_profit_vat_reg = npVatReg;
      total_net_profit_percentage_tax = npPct;
    });
  }

  @override
  void initState() {
    _refreshAll();
    super.initState();
  }

  // ===== UI helpers (right-aligned values like VAT page) =====
  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          // Right-aligned value column
          Expanded(
            child: Text(
              value,
              style: _valueStyle,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // top bar like other pages
          Container(
            height: 75,
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(bottom: BorderSide(color: Color(0xFFA4A4A4))),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF161616),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Date range card
                        _card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                            ),
                            title: Text(
                              "Date Range: ${DateFormat('MMMM d').format(utcStartDate!.toLocal())} to ${DateFormat('MMMM d').format(utcEndDate!.toLocal())}",
                              style: _dateStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100),
                                initialDateRange: DateTimeRange(
                                  start: DateTime(now.year, now.month, 1),
                                  end: now,
                                ),
                              );
                              if (picked == null) return;

                              final startDate = picked.start;
                              final endDate = picked.end;

                              setState(() {
                                utcStartDate = DateTime.utc(
                                  startDate.year,
                                  startDate.month,
                                  startDate.day,
                                );
                                utcEndDate = DateTime.utc(
                                  endDate.year,
                                  endDate.month,
                                  endDate.day,
                                ).add(const Duration(days: 1));

                                _refreshAll();
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Report card
                        _card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    6,
                                    14,
                                    10,
                                  ),
                                  child: Text(
                                    "Tax Report (Not VAT-Registered)",
                                    style: _titleStyle,
                                  ),
                                ),
                                const Divider(
                                  color: Color(0xFF3A3A3A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Total Gross Sales",
                                  _nf.format(total_gross_sales),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Total COGs",
                                  _nf.format(total_cogs),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Total Gross Profit",
                                  _nf.format(total_gross_profit),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Operating Expenses",
                                  _nf.format(total_expenses),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Net Profit (Before Taxes)",
                                  _nf.format(total_net_profit_before_taxes),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Percentage Tax",
                                  _nf.format(total_gross_sales * 0.03),
                                ),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),

                                _metricRow(
                                  "Net Profit (minus Percentage Tax)",
                                  _nf.format(total_net_profit_percentage_tax),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
