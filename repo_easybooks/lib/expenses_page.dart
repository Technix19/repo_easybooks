// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:repo_easybooks/data/export_table_as_csv.dart';
import 'package:repo_easybooks/formula.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

// ---- Nice numbers for axis ticks (same helper as Income) ----
double _niceNum(double range, {required bool round}) {
  final exponent = (math.log(range) / math.ln10).floor();
  final fraction = range / math.pow(10, exponent);
  double niceFraction;
  if (round) {
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  } else {
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  }
  return niceFraction * math.pow(10, exponent);
}

class _ExpensesPageState extends State<ExpensesPage> {
  final formula = Formula();
  final supabase = Supabase.instance.client;

  // Chart fill palette (same as Income)
  final List<Color> gradientColors = const [
    Color(0xFF232B6E),
    Color(0xFF02D39A),
  ];

  // Currency formatter (for “More Info” + list)
  final _php = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  // Form fields
  bool? isVAT_registered = false;
  String expense_name = '';
  String expense_description = '';
  String price_per_unit_str = '';
  String amount_of_units_str = '';

  double parsed_price_per_unit = 0;
  int parsed_amount_of_units = 0;
  double parsed_total_expenses = 0;
  double parsed_input_VAT = 0;
  double parsed_total_expenses_minus_VAT = 0;

  // Update fields
  String update_expense_name = '';
  String update_expense_description = '';
  String update_price_per_unit_str = '';
  String update_amount_of_units_str = '';
  bool? update_isVAT_registered = false;
  double update_parsed_price_per_unit = 0;
  double update_parsed_amount_of_units = 0;

  // Date range (end exclusive; include “today”)
  DateTime? utcStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime? utcEndDate = DateTime.now().add(const Duration(days: 1));

  // Data sources
  Future<List<Map<String, dynamic>>>? expenses_database;
  late Future<List<dynamic>> dailyExpensesFuture; // chart data

  Future<List<Map<String, dynamic>>> _fetchDate({
    required DateTime utcStartDate,
    required DateTime utcEndDate,
  }) async {
    final data = await supabase
        .from('expense')
        .select('*')
        .gte('created_at', utcStartDate.toIso8601String())
        .lt('created_at', utcEndDate.toIso8601String())
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  // RPC rows like: { day: 'YYYY-MM-DD', total_expenses: number }
  Future<List<dynamic>> _fetchDailyExpenses({
    required DateTime utcStart,
    required DateTime utcEnd,
  }) async {
    try {
      final res = await supabase.rpc(
        'get_daily_expenses',
        params: {
          'start_date': utcStart.toIso8601String(),
          'end_date': utcEnd.toIso8601String(),
          'tz': 'Asia/Manila',
        },
      );
      return (res is List) ? res : <dynamic>[];
    } catch (e) {
      debugPrint('Error fetching daily expenses: $e');
      return <dynamic>[];
    }
  }

  @override
  void initState() {
    super.initState();
    expenses_database = _fetchDate(
      utcStartDate: utcStartDate!,
      utcEndDate: utcEndDate!,
    );
    dailyExpensesFuture = _fetchDailyExpenses(
      utcStart: utcStartDate!,
      utcEnd: utcEndDate!,
    );
  }

  // ---------- INCOME-PAGE DESIGN PRIMITIVES (copied) ----------
  static const _bg = Color(0xFF161616);
  static const _card = Color(0xFF1E1E1E);
  static const _border = Color(0xFF717171);
  static const _thinBorder = Color(0xFF3A3A3A);
  static const _muted = Color(0xFFBDBDBD);
  static const _muted2 = Color(0xFF9E9E9E);
  static const _accent = Color(0xFF6FFF43);

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _muted2),
    filled: true,
    fillColor: const Color(0xFF242424),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _thinBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _accent),
    ),
  );

  AlertDialog _dialogShell({
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool showClose = true,
  }) {
    return AlertDialog(
      backgroundColor: _card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _thinBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          if (showClose)
            IconButton(
              splashRadius: 18,
              icon: const Icon(Icons.close, color: _muted, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      content: content,
      actions: actions,
      actionsAlignment: MainAxisAlignment.center,
    );
  }

  String _fmtDateLong(DateTime d) {
    const m = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateTile({required String label, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _thinBorder),
        ),
        child: ListTile(
          dense: true,
          title: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.edit, color: _muted),
          ),
        ),
      ),
    );
  }

  // ---------- CHART (kept, but styled text to white for dark card) ----------
  Widget buildDailyLineChart({
    required BuildContext context,
    required List<dynamic> rows,
    required String title,
    required String valueKey, // 'total_expenses'
  }) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No data found for this range.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final normalized =
        rows
            .map<Map<String, dynamic>>(
              (e) => {
                'day': DateTime.parse(e['day'] as String),
                'value': (e[valueKey] as num).toDouble(),
              },
            )
            .toList()
          ..sort(
            (a, b) => (a['day'] as DateTime).compareTo(b['day'] as DateTime),
          );

    final dates = normalized.map((e) => e['day'] as DateTime).toList();
    final values = normalized.map((e) => e['value'] as double).toList();

    final baseDate = dates.first;
    final spots = List<FlSpot>.generate(
      values.length,
      (i) => FlSpot(dates[i].difference(baseDate).inDays.toDouble(), values[i]),
    );

    final minX = 0.0;
    final maxX = dates.last.difference(baseDate).inDays.toDouble();
    final spanDays = (maxX - minX).round();
    final xInterval = (spanDays <= 6)
        ? 1.0
        : (spanDays / 6).floorToDouble().clamp(1.0, 999.0);

    String xLabel(double x) {
      final d = baseDate.add(Duration(days: x.round()));
      return '${d.month}/${d.day}';
    }

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY = (minY - 1).clamp(0, double.infinity);
      maxY += 1;
    }
    final rawMin = math.max(0, minY);
    final rawMax = maxY;
    final rawRange = (rawMax - rawMin).abs();
    const desiredTicks = 6;
    final niceRange = _niceNum(rawRange, round: true);
    final yInterval = _niceNum(niceRange / desiredTicks, round: true);
    final chartMinY = (rawMin / yInterval).floor() * yInterval;
    final chartMaxY = (rawMax / yInterval).ceil() * yInterval;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Daily Total Expenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: chartMinY,
              maxY: chartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Color(0x22FFFFFF), strokeWidth: 0.5),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) {
                      if (value < minX - 0.5 || value > maxX + 0.5) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          xLabel(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  color: Theme.of(context).colorScheme.primary,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors
                          .map((c) => c.withOpacity(0.30))
                          .toList(),
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touched) => touched.map((t) {
                    final dateLabel = xLabel(t.x);
                    return LineTooltipItem(
                      '$dateLabel\n₱${t.y.toStringAsFixed(2)}',
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            duration: const Duration(milliseconds: 450),
          ),
        ),
      ],
    );
  }

  // ---------- UI (exact same structure and sizes as Income) ----------
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Top bar (height 75) with breadcrumb style
          Container(
            height: 75,
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(bottom: BorderSide(color: _muted)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Dashboard ',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '/ ',
                        style: TextStyle(
                          color: _muted2,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: 'Expenses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: Container(
              color: _bg,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    // Top row: Chart (left) + Date card & Add button (right)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          // LEFT: Chart card
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _card,
                                border: Border.all(color: _border),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: FutureBuilder<List<dynamic>>(
                                  future: dailyExpensesFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child:
                                            CircularProgressIndicator.adaptive(),
                                      );
                                    }
                                    final rows = snapshot.data ?? <dynamic>[];
                                    return buildDailyLineChart(
                                      context: context,
                                      rows: rows,
                                      title: 'Daily Total Expenses',
                                      valueKey: 'total_expenses',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // RIGHT: Date card + Add button (exact sizes)
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Column(
                              children: [
                                // Date Range Card (220 x 250)
                                Container(
                                  height: 220,
                                  width: 250,
                                  decoration: BoxDecoration(
                                    color: _card,
                                    border: Border.all(color: _border),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2100),
                                        initialDateRange: DateTimeRange(
                                          start: DateTime(
                                            now.year,
                                            now.month,
                                            1,
                                          ),
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
                                        // end is exclusive (+1 day)
                                        utcEndDate = DateTime.utc(
                                          endDate.year,
                                          endDate.month,
                                          endDate.day,
                                        ).add(const Duration(days: 1));

                                        // refresh list + chart
                                        expenses_database = _fetchDate(
                                          utcStartDate: utcStartDate!,
                                          utcEndDate: utcEndDate!,
                                        );
                                        dailyExpensesFuture =
                                            _fetchDailyExpenses(
                                              utcStart: utcStartDate!,
                                              utcEnd: utcEndDate!,
                                            );
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.calendar_month,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                "Date Range",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Center(
                                            child: Column(
                                              children: [
                                                Text(
                                                  _fmtDateLong(
                                                    (utcStartDate ??
                                                            DateTime.now())
                                                        .toLocal(),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                const Icon(
                                                  Icons.arrow_downward,
                                                  size: 18,
                                                  color: _muted,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _fmtDateLong(
                                                    ((utcEndDate ??
                                                                DateTime.now())
                                                            .toLocal())
                                                        .subtract(
                                                          const Duration(
                                                            days: 1,
                                                          ),
                                                        ),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22.5),

                                // Add Record button (width 250, height ~55)
                                SizedBox(
                                  width: 250,
                                  height: 55,
                                  child: Row(
                                    children: [
                                      // Add Record (unchanged)
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: const ButtonStyle(
                                            backgroundColor:
                                                MaterialStatePropertyAll(_card),
                                            foregroundColor:
                                                MaterialStatePropertyAll(
                                                  Colors.white,
                                                ),
                                            shape: MaterialStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(20),
                                                ),
                                                side: BorderSide(
                                                  color: _border,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                          onPressed: _openAddDialog,
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            "Add",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: _border,
                                              width: 1,
                                            ),
                                            backgroundColor: _card,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final user = Supabase
                                                  .instance
                                                  .client
                                                  .auth
                                                  .currentUser;
                                              if (user == null) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Please sign in to export your data.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              await exportTableToCsv(
                                                table:
                                                    'expense', // your table name in Supabase
                                                fileBaseName: 'expenses_record',
                                                eq: {
                                                  'user_id': user.id,
                                                }, // filter to this user's data
                                              );

                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'CSV exported successfully!',
                                                  ),
                                                  backgroundColor:
                                                      Colors.lightGreenAccent,
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error exporting CSV: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.download_outlined,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Export',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Records list (same shell & row look as Income)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: _thinBorder),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: expenses_database,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator.adaptive(),
                              );
                            }

                            final expense_data = snapshot.data!;
                            if (expense_data.isEmpty) {
                              return const Center(
                                child: Text(
                                  "There were no records found in the specified date range",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: expense_data.length,
                              itemBuilder: (context, index) {
                                final row = expense_data[index];

                                void onMoreInfo() {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return _dialogShell(
                                        title: "More Info",
                                        content: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 480,
                                            maxWidth: 640,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _infoRow("   ID", "${row['id']}"),
                                              _infoRow(
                                                "   Date",
                                                "${row['created_at']}",
                                              ),
                                              _infoRow(
                                                "   Expense Name",
                                                "${row['expense_name']}",
                                              ),
                                              _infoRow(
                                                "   Description",
                                                "${row['description']}",
                                              ),
                                              _infoRow(
                                                "   Price per Unit",
                                                _php.format(
                                                  (row['price_per_unit'] ?? 0)
                                                      as num,
                                                ),
                                              ),
                                              _infoRow(
                                                "   Amount of Units",
                                                "${row['amount_of_units']}",
                                              ),
                                              _infoRow(
                                                "   VAT Registered",
                                                ((row['is_vat_registered']
                                                            as bool?) ??
                                                        false)
                                                    ? "Yes"
                                                    : "No",
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _card,
                                                  border: Border.all(
                                                    color: _thinBorder,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    if ((row['is_vat_registered']
                                                            as bool?) ??
                                                        false) ...[
                                                      _infoRow(
                                                        "Input VAT",
                                                        _php.format(
                                                          (row['input_vat'] ??
                                                                  0)
                                                              as num,
                                                        ),
                                                      ),
                                                      _infoRow(
                                                        "Total (VAT Excluded)",
                                                        _php.format(
                                                          (row['total_expenses_minus_vat'] ??
                                                                  0)
                                                              as num,
                                                        ),
                                                      ),
                                                      const Divider(
                                                        color: _thinBorder,
                                                      ),
                                                      _infoRow(
                                                        "Total (VAT Included)",
                                                        _php.format(
                                                          (row['total_expenses'] ??
                                                                  0)
                                                              as num,
                                                        ),
                                                      ),
                                                    ] else
                                                      _infoRow(
                                                        "Total Expenses",
                                                        _php.format(
                                                          (row['total_expenses'] ??
                                                                  0)
                                                              as num,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }

                                void onEdit() {
                                  showDialog(
                                    context: context,
                                    builder: (dlgCtx) {
                                      return _dialogShell(
                                        title: "Update Content",
                                        content: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 420,
                                            maxWidth: 520,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _updateTile(
                                                label:
                                                    "Current Expense Name: ${row['expense_name']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Expense Name",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "New Expense Name",
                                                      ),
                                                      onChanged: (v) =>
                                                          update_expense_name =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        if (update_expense_name
                                                            .isEmpty) {
                                                          throw Exception(
                                                            "Name Field can't be empty!",
                                                          );
                                                        }
                                                        await supabase
                                                            .from('expense')
                                                            .update({
                                                              'expense_name':
                                                                  update_expense_name,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        update_expense_name =
                                                            '';
                                                        _refresh();
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              "Error: $e",
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                              _updateTile(
                                                label:
                                                    "Current Description: ${row['description']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title: "Update Description",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "New Description",
                                                      ),
                                                      onChanged: (v) =>
                                                          update_expense_description =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        await supabase
                                                            .from('expense')
                                                            .update({
                                                              'description':
                                                                  update_expense_description,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        update_expense_description =
                                                            '';
                                                        _refresh();
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              "Error: $e",
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                              _updateTile(
                                                label:
                                                    "Current Price per Unit: ${row['price_per_unit']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Price per Unit",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "New Price per Unit",
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) =>
                                                          update_price_per_unit_str =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        update_parsed_price_per_unit =
                                                            double.parse(
                                                              update_price_per_unit_str,
                                                            );

                                                        if (update_parsed_price_per_unit < //Bug Fixed. Value Can't Be Negative
                                                            0) {
                                                          throw Exception(
                                                            "Invalid Input! Value Can't Be Negative!",
                                                          );
                                                        }

                                                        final newTotal = formula
                                                            .getTotalExpenses(
                                                              (row['amount_of_units']
                                                                      as num)
                                                                  .toDouble(),
                                                              update_parsed_price_per_unit,
                                                            );
                                                        final newVAT = formula
                                                            .getInputVAT(
                                                              newTotal,
                                                            );
                                                        final newMinusVAT = formula
                                                            .getTotalExpensesMinusVAT(
                                                              newTotal,
                                                              newVAT,
                                                            );

                                                        await supabase
                                                            .from('expense')
                                                            .update({
                                                              'price_per_unit':
                                                                  update_parsed_price_per_unit,
                                                              'total_expenses':
                                                                  newTotal,
                                                              'input_vat':
                                                                  newVAT,
                                                              'total_expenses_minus_vat':
                                                                  newMinusVAT,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );

                                                        update_price_per_unit_str =
                                                            '';
                                                        _refresh(full: true);
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              "Error: $e",
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                              _updateTile(
                                                label:
                                                    "Current Amount of Units: ${row['amount_of_units']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Amount of Units",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "New Amount of Units",
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) =>
                                                          update_amount_of_units_str =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        update_parsed_amount_of_units =
                                                            double.parse(
                                                              update_amount_of_units_str,
                                                            );

                                                        if (update_parsed_amount_of_units <= //Bug Fixed. Value Can't Be Negative
                                                            0) {
                                                          throw Exception(
                                                            "Amount of Units can't be zero!",
                                                          );
                                                        }

                                                        final newTotal = formula
                                                            .getTotalExpenses(
                                                              update_parsed_amount_of_units,
                                                              (row['price_per_unit']
                                                                      as num)
                                                                  .toDouble(),
                                                            );
                                                        final newVAT = formula
                                                            .getInputVAT(
                                                              newTotal,
                                                            );
                                                        final newMinusVAT = formula
                                                            .getTotalExpensesMinusVAT(
                                                              newTotal,
                                                              newVAT,
                                                            );

                                                        await supabase
                                                            .from('expense')
                                                            .update({
                                                              'amount_of_units':
                                                                  update_parsed_amount_of_units,
                                                              'total_expenses':
                                                                  newTotal,
                                                              'input_vat':
                                                                  newVAT,
                                                              'total_expenses_minus_vat':
                                                                  newMinusVAT,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );

                                                        update_amount_of_units_str =
                                                            '';
                                                        _refresh(full: true);
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              "Error: $e",
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                              _updateTile(
                                                label:
                                                    "Vendor is VAT-registered: ${row['is_vat_registered']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  update_isVAT_registered =
                                                      (row['is_vat_registered']
                                                          as bool?) ??
                                                      false;
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return _dialogShell(
                                                        title:
                                                            "Update VAT Status",
                                                        content: StatefulBuilder(
                                                          builder: (c, setStateDialog) {
                                                            return CheckboxListTile.adaptive(
                                                              title: const Text(
                                                                "Vendor is VAT-registered",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              value:
                                                                  update_isVAT_registered,
                                                              onChanged: (v) =>
                                                                  setStateDialog(
                                                                    () =>
                                                                        update_isVAT_registered =
                                                                            v,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                        actions: [
                                                          OutlinedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            child: const Text(
                                                              "Cancel",
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () async {
                                                              await supabase
                                                                  .from(
                                                                    'expense',
                                                                  )
                                                                  .update({
                                                                    'is_vat_registered':
                                                                        update_isVAT_registered,
                                                                  })
                                                                  .eq(
                                                                    'id',
                                                                    row['id'],
                                                                  );
                                                              if (!mounted)
                                                                return;
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              _refresh();
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .lightGreenAccent,
                                                                  content: Text(
                                                                    "Record Updated Successfully!",
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              "Update",
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }

                                void onDelete() {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return _dialogShell(
                                        title: "Delete Record",
                                        content: const Text(
                                          "This action cannot be undone.\nAre you sure you want to delete this record?",
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            height: 1.35,
                                          ),
                                        ),
                                        actions: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFFE0E0E0,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFF6A6A6A),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFF5252,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () async {
                                              try {
                                                await supabase
                                                    .from(
                                                      'expense',
                                                    ) // Bug Fixed
                                                    .delete()
                                                    .eq('id', row['id']);
                                                if (!mounted) return;
                                                Navigator.pop(context);
                                                _refresh(full: true);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Colors.lightGreenAccent,
                                                    content: Text(
                                                      "Record has been deleted successfully",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } on AuthException catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.red,
                                                    content: Text("Error: $e"),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: onMoreInfo,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _thinBorder,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.book_outlined,
                                            color: _muted,
                                          ),
                                          title: Row(
                                            children: [
                                              // Expense Name
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 50,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text:
                                                              'Expense Name: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${row['expense_name'] ?? '-'}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              // Description
                                              Expanded(
                                                flex: 4,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 50,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Description: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${row['description'] ?? '-'}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              // Units
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 50,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Units: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${row['amount_of_units'] ?? '-'}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              // Total
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 50,
                                                      ),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Total: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: _php.format(
                                                            (row['total_expenses'] ??
                                                                    0)
                                                                as num,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: onEdit,
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: _muted,
                                                  size: 18,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 28,
                                                      height: 28,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                onPressed: onDelete,
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: _muted,
                                                  size: 18,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 28,
                                                      height: 28,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helpers (refresh + dialogs) ----------
  void _refresh({bool full = false}) {
    setState(() {
      expenses_database = _fetchDate(
        utcStartDate: utcStartDate!,
        utcEndDate: utcEndDate!,
      );
      if (full) {
        dailyExpensesFuture = _fetchDailyExpenses(
          utcStart: utcStartDate!,
          utcEnd: utcEndDate!,
        );
      }
    });
  }

  void _openUpdateField({
    required String title,
    required Widget field,
    required Future<void> Function() onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _dialogShell(
          title: title,
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field,
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await onSubmit();
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.lightGreenAccent,
                            content: Text(
                              "Record Updated Successfully!",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text("Error: $e"),
                          ),
                        );
                      }
                    },
                    child: const Text("Update"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _dialogShell(
          title: "Add Expense Record",
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Expense Name"),
                      onChanged: (v) => setState(() => expense_name = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Expense Description"),
                      onChanged: (v) => setState(() => expense_description = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Expense Price per Unit"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => price_per_unit_str = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Total Units"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => amount_of_units_str = v),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile.adaptive(
                      title: const Text(
                        'Vendor is VAT-registered',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: isVAT_registered,
                      onChanged: (value) =>
                          setStateDialog(() => isVAT_registered = value),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isVAT_registered = false;
                              expense_name = '';
                              expense_description = '';
                              price_per_unit_str = '';
                              amount_of_units_str = '';
                              expenses_database = _fetchDate(
                                utcStartDate: utcStartDate!,
                                utcEndDate: utcEndDate!,
                              );
                              dailyExpensesFuture = _fetchDailyExpenses(
                                utcStart: utcStartDate!,
                                utcEnd: utcEndDate!,
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            //Debug Fixed- this is just for reference so I can copy paste
                            try {
                              parsed_price_per_unit = double.parse(
                                price_per_unit_str,
                              );
                              parsed_amount_of_units = int.parse(
                                amount_of_units_str,
                              );
                              if (parsed_amount_of_units < 1 ||
                                  parsed_price_per_unit < 0) {
                                throw Exception('Error: Invalid Input!');
                              }

                              if (expense_name.isEmpty) {
                                throw Exception("Name Field Can't Be Empty!");
                              }

                              parsed_total_expenses = formula.getTotalExpenses(
                                parsed_amount_of_units.toDouble(),
                                parsed_price_per_unit,
                              );
                              parsed_input_VAT = formula.getInputVAT(
                                parsed_total_expenses,
                              );
                              parsed_total_expenses_minus_VAT = formula
                                  .getTotalExpensesMinusVAT(
                                    parsed_total_expenses,
                                    parsed_input_VAT,
                                  );

                              await supabase.from('expense').insert({
                                'expense_name': expense_name,
                                'description': expense_description,
                                'price_per_unit': parsed_price_per_unit,
                                'amount_of_units': parsed_amount_of_units,
                                'is_vat_registered': isVAT_registered,
                                'input_vat': parsed_input_VAT,
                                'total_expenses': parsed_total_expenses,
                                'total_expenses_minus_vat':
                                    parsed_total_expenses_minus_VAT,
                              });

                              setState(() {
                                isVAT_registered = false;
                                expense_name = '';
                                expense_description = '';
                                price_per_unit_str = '';
                                amount_of_units_str = '';
                                expenses_database = _fetchDate(
                                  utcStartDate: utcStartDate!,
                                  utcEndDate: utcEndDate!,
                                );
                                dailyExpensesFuture = _fetchDailyExpenses(
                                  utcStart: utcStartDate!,
                                  utcEnd: utcEndDate!,
                                );
                              });

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.lightGreenAccent,
                                  content: Text(
                                    "Your record has been saved!",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text("Error! $e"),
                                ),
                              );
                            }
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
