// ignore_for_file: deprecated_member_use
import 'dart:developer';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:repo_easybooks/data/export_table_as_csv.dart';
import 'package:repo_easybooks/formula.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

// ---- Nice numbers for axis ticks (unchanged) ----
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

class _IncomePageState extends State<IncomePage> {
  final formula = Formula();
  final supabase = Supabase.instance.client;

  // Palette (used for fills if needed)
  final List<Color> gradientColors = const [
    Color(0xFF232B6E),
    Color(0xFF02D39A),
  ];

  // Currency formatting for list “More Info”
  final _php = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  // Form fields
  String product_name = '';
  String product_description = '';
  String quantity_str = '';
  String selling_price_str = '';
  String cogs_per_unit_str = '';
  int quantity = 0;
  double selling_price_per_unit = 0;
  double cogs_per_unit = 0;

  // Update fields
  String updateProductName = '';
  String updateProductDescription = '';
  String updateQuantity_str = '';
  String updateSellingPricePerUnit_str = '';
  String updateCOGsPerUnit_str = '';
  int update_parsed_quantity = 0;
  double update_parsed_sellingPricePerUnit = 0;
  double update_parsed_COGSPerUnit = 0;

  // Date range (end exclusive; default now+1d)
  DateTime? utcStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime? utcEndDate = DateTime.now().add(const Duration(days: 1));

  // Data sources
  Future<List<Map<String, dynamic>>>? income_database;
  late Future<List<dynamic>> dailySalesFuture;

  Future<List<Map<String, dynamic>>> _fetchDate({
    required DateTime utcStartDate,
    required DateTime utcEndDate,
  }) async {
    final data = await supabase
        .from('income')
        .select('*')
        .gte('created_at', utcStartDate.toIso8601String())
        .lt('created_at', utcEndDate.toIso8601String())
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<dynamic>> _fetchDailySales({
    required DateTime utcStartDate,
    required DateTime utcEndDate,
  }) async {
    try {
      final res = await supabase.rpc(
        'get_daily_income_sales',
        params: {
          'start_date': utcStartDate.toIso8601String(),
          'end_date': utcEndDate.toIso8601String(),
          'tz': 'Asia/Manila',
        },
      );
      return (res is List) ? res : <dynamic>[];
    } catch (e) {
      debugPrint('Error fetching daily income sales: $e');
      return <dynamic>[];
    }
  }

  @override
  void initState() {
    super.initState();
    income_database = _fetchDate(
      utcStartDate: utcStartDate!,
      utcEndDate: utcEndDate!,
    );
    dailySalesFuture = _fetchDailySales(
      utcStartDate: utcStartDate!,
      utcEndDate: utcEndDate!,
    );
  }

  // ---------- EXPENSES-PAGE DESIGN PRIMITIVES ----------
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

  // ---------- CHART (your logic preserved) ----------
  Widget buildDailyLineChart({
    required BuildContext context,
    required List<dynamic> rows,
    required String title,
    required String valueKey,
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

    String formatDayFromX(double x) {
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
            'Daily Total Gross Sales',
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
                          formatDayFromX(value),
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
                    final labelDate = formatDayFromX(t.x);
                    return LineTooltipItem(
                      '$labelDate\n₱${t.y.toStringAsFixed(2)}',
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

  // ---------- UI (sizes & structure exactly mirror Expenses) ----------
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Top bar (same size 75)
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
                        text: 'Income',
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
                    // Top row 300px high — Left card (chart) + Right column (date + add/export)
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
                                  future: dailySalesFuture,
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
                                      title: 'Daily Total Gross Sales',
                                      valueKey: 'total_sales',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // RIGHT: Date card (220x250) + Buttons row (Add + Export)
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Column(
                              children: [
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
                                        // end exclusive (+1 day)
                                        utcEndDate = DateTime.utc(
                                          endDate.year,
                                          endDate.month,
                                          endDate.day,
                                        ).add(const Duration(days: 1));

                                        income_database = _fetchDate(
                                          utcStartDate: utcStartDate!,
                                          utcEndDate: utcEndDate!,
                                        );
                                        dailySalesFuture = _fetchDailySales(
                                          utcStartDate: utcStartDate!,
                                          utcEndDate: utcEndDate!,
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

                                // ⬇️ Buttons row: Add Record + Export (side-by-side)
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
                                      // NEW: Export button (placeholder onTap)
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
                                                    'income', // your table name in Supabase
                                                fileBaseName: 'income_record',
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
                                                  backgroundColor: Colors.green,
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

                    // Records list (same shell & row look as Expenses)
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
                          future: income_database,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator.adaptive(),
                              );
                            }
                            final data = snapshot.data!;
                            if (data.isEmpty) {
                              return const Center(
                                child: Text(
                                  "There are no records in your specified date range",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final row = data[index];

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
                                                "   Name",
                                                "${row['product_name']}",
                                              ),
                                              _infoRow(
                                                "   Description",
                                                "${row['description']}",
                                              ),
                                              _infoRow(
                                                "   Quantity",
                                                "${row['quantity']}",
                                              ),
                                              _infoRow(
                                                "   Unit Price",
                                                _php.format(
                                                  (row['selling_price_per_unit'] ??
                                                          0)
                                                      as num,
                                                ),
                                              ),
                                              _infoRow(
                                                "   COGs per Unit",
                                                _php.format(
                                                  (row['cogs_per_unit'] ?? 0)
                                                      as num,
                                                ),
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
                                                    _infoRow(
                                                      "Gross Profit",
                                                      _php.format(
                                                        (row['computed_gross_profit'] ??
                                                                0)
                                                            as num,
                                                      ),
                                                    ),
                                                    _infoRow(
                                                      "Total COGs",
                                                      _php.format(
                                                        (row['total_cogs'] ?? 0)
                                                            as num,
                                                      ),
                                                    ),
                                                    _infoRow(
                                                      "Output VAT",
                                                      _php.format(
                                                        (row['output_vat'] ?? 0)
                                                            as num,
                                                      ),
                                                    ),
                                                    const Divider(
                                                      color: _thinBorder,
                                                    ),
                                                    _infoRow(
                                                      "Total Gross Sale Amount",
                                                      _php.format(
                                                        (row['total_gross_sales'] ??
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
                                                    "Current Product Name: ${row['product_name']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Product Name",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "Enter New Product Name",
                                                      ),
                                                      onChanged: (v) =>
                                                          updateProductName = v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        if (updateProductName
                                                            .isEmpty) {
                                                          throw Exception(
                                                            'Name Can\'t Be Empty!',
                                                          );
                                                        }
                                                        await supabase
                                                            .from('income')
                                                            .update({
                                                              'product_name':
                                                                  updateProductName,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        updateProductName = '';
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
                                                    "Current Product Description: ${row['description']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Product Description",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "Enter New Product Description",
                                                      ),
                                                      onChanged: (v) =>
                                                          updateProductDescription =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        await supabase
                                                            .from('income')
                                                            .update({
                                                              'description':
                                                                  updateProductDescription,
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        updateProductDescription =
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
                                                    "Current Quantity: ${row['quantity']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title: "Update Quantity",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "Enter New Quantity",
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) =>
                                                          updateQuantity_str =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        update_parsed_quantity =
                                                            int.parse(
                                                              updateQuantity_str,
                                                            );
                                                        if (update_parsed_quantity <= //Bug Fixed. Value Can't Be Negative
                                                            0) {
                                                          throw Exception(
                                                            'Invalid Input!',
                                                          );
                                                        }
                                                        await supabase
                                                            .from('income')
                                                            .update({
                                                              'quantity':
                                                                  update_parsed_quantity,
                                                              'computed_gross_profit': formula.getComputedGrossProfit(
                                                                update_parsed_quantity,
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                                (row['cogs_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'total_cogs': formula.getTotalCOGs(
                                                                update_parsed_quantity,
                                                                (row['cogs_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'output_vat': formula.getOutputVAT(
                                                                update_parsed_quantity,
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'total_gross_sales': formula.getTotalGrossSales(
                                                                update_parsed_quantity,
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        updateQuantity_str = '';
                                                        _refresh();
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          // Bug Fixed: Error handling
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
                                                    "Current Selling Price per Unit: ${row['selling_price_per_unit']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update Selling Price per Unit",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "Enter New Selling Price Per Unit",
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) =>
                                                          updateSellingPricePerUnit_str =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        update_parsed_sellingPricePerUnit =
                                                            double.parse(
                                                              updateSellingPricePerUnit_str,
                                                            );

                                                        if (update_parsed_sellingPricePerUnit < //Bug Fixed. Value Can't Be Negative
                                                            0) {
                                                          throw Exception(
                                                            "Invalid Input!",
                                                          );
                                                        }
                                                        await supabase
                                                            .from('income')
                                                            .update({
                                                              'selling_price_per_unit':
                                                                  update_parsed_sellingPricePerUnit,
                                                              'computed_gross_profit': formula.getComputedGrossProfit(
                                                                (row['quantity']
                                                                        as num)
                                                                    .toInt(),
                                                                update_parsed_sellingPricePerUnit,
                                                                (row['cogs_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'total_cogs': formula.getTotalCOGs(
                                                                (row['quantity']
                                                                        as num)
                                                                    .toInt(),
                                                                (row['cogs_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'output_vat': formula
                                                                  .getOutputVAT(
                                                                    (row['quantity']
                                                                            as num)
                                                                        .toInt(),
                                                                    update_parsed_sellingPricePerUnit,
                                                                  ),
                                                              'total_gross_sales':
                                                                  formula.getTotalGrossSales(
                                                                    (row['quantity']
                                                                            as num)
                                                                        .toInt(),
                                                                    update_parsed_sellingPricePerUnit,
                                                                  ),
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        updateSellingPricePerUnit_str =
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
                                                    "Current Cost to Fulfill Each Unit: ${row['cogs_per_unit']}",
                                                onPressed: () {
                                                  Navigator.of(dlgCtx).pop();
                                                  _openUpdateField(
                                                    title:
                                                        "Update COGs per Unit",
                                                    field: TextField(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      decoration: _input(
                                                        "Enter New COGs Per Unit",
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) =>
                                                          updateCOGsPerUnit_str =
                                                              v,
                                                    ),
                                                    onSubmit: () async {
                                                      try {
                                                        update_parsed_COGSPerUnit =
                                                            double.parse(
                                                              updateCOGsPerUnit_str,
                                                            );

                                                        if (update_parsed_COGSPerUnit < //Bug Fixed. Value Can't Be Negative
                                                            0) {
                                                          throw Exception(
                                                            "Invalid Input!", //Bug Fixed. Input not throwing error
                                                          );
                                                        }
                                                        await supabase
                                                            .from('income')
                                                            .update({
                                                              'cogs_per_unit':
                                                                  update_parsed_COGSPerUnit,
                                                              'computed_gross_profit': formula.getComputedGrossProfit(
                                                                (row['quantity']
                                                                        as num)
                                                                    .toInt(),
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                                update_parsed_COGSPerUnit,
                                                              ),
                                                              'total_cogs': formula
                                                                  .getTotalCOGs(
                                                                    (row['quantity']
                                                                            as num)
                                                                        .toInt(),
                                                                    update_parsed_COGSPerUnit,
                                                                  ),
                                                              'output_vat': formula.getOutputVAT(
                                                                (row['quantity']
                                                                        as num)
                                                                    .toInt(),
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                              'total_gross_sales': formula.getTotalGrossSales(
                                                                (row['quantity']
                                                                        as num)
                                                                    .toInt(),
                                                                (row['selling_price_per_unit']
                                                                        as num)
                                                                    .toDouble(),
                                                              ),
                                                            })
                                                            .eq(
                                                              'id',
                                                              row['id'],
                                                            );
                                                        updateCOGsPerUnit_str =
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
                                                              "Error! $e",
                                                            ),
                                                          ),
                                                        );
                                                      }
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
                                                    .from('income')
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
                                              // Product Name
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
                                                              'Product Name: ',
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
                                                              '${row['product_name'] ?? '-'}',
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
                                              // Quantity
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
                                                          text: 'Quantity: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${row['quantity'] ?? '-'}',
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
                                              // Total Gross Sale
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
                                                              'Total Gross Sale: ',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFBEBEBE,
                                                            ),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: _php.format(
                                                            (row['total_gross_sales'] ??
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

  // ---------- Helpers (update shell + add record) ----------
  void _refresh({bool full = false}) {
    setState(() {
      income_database = _fetchDate(
        utcStartDate: utcStartDate!,
        utcEndDate: utcEndDate!,
      );
      if (full) {
        dailySalesFuture = _fetchDailySales(
          utcStartDate: utcStartDate!,
          utcEndDate: utcEndDate!,
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
                      await onSubmit();
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.lightGreenAccent,
                          content: Text(
                            "Record has been updated successfully",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
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
          title: "Add Income Record",
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Product Name"),
                  onChanged: (v) => setState(() => product_name = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Product Description"),
                  onChanged: (v) => setState(() => product_description = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Quantity"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => quantity_str = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Unit Price"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => selling_price_str = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Cost to Fulfill"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => cogs_per_unit_str = v),
                ),
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
                        quantity = int.parse(quantity_str);
                        selling_price_per_unit = double.parse(
                          selling_price_str,
                        );
                        cogs_per_unit = double.parse(cogs_per_unit_str);

                        //Bug Fixed- Add If Condition to Avoid Null Input

                        //Check Values and Validate
                        if (product_name.isEmpty) {
                          throw Exception("Name Field Can't Be Empty!");
                        }
                        if (quantity < 1 || cogs_per_unit < 0) {
                          throw Exception("Error: Invalid Input!");
                        }
                      } catch (e) {
                        if (!mounted) return;
                        log(
                          '$quantity | $selling_price_per_unit | $cogs_per_unit}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text("Error: $e"),
                          ),
                        );
                        return;
                      }

                      try {
                        await supabase.from('income').insert({
                          'product_name': product_name,
                          'description': product_description,
                          'quantity': quantity,
                          'selling_price_per_unit': selling_price_per_unit,
                          'cogs_per_unit': cogs_per_unit,
                          'computed_gross_profit': formula
                              .getComputedGrossProfit(
                                quantity,
                                selling_price_per_unit,
                                cogs_per_unit,
                              ),
                          'total_cogs': formula.getTotalCOGs(
                            quantity,
                            cogs_per_unit,
                          ),
                          'output_vat': formula.getOutputVAT(
                            quantity,
                            selling_price_per_unit,
                          ),
                          'total_gross_sales': formula.getTotalGrossSales(
                            quantity,
                            selling_price_per_unit,
                          ),
                        });

                        setState(() {
                          product_name = '';
                          product_description = '';
                          quantity_str = '';
                          selling_price_str = '';
                          cogs_per_unit_str = '';
                          income_database = _fetchDate(
                            utcStartDate: utcStartDate!,
                            utcEndDate: utcEndDate!,
                          );
                          dailySalesFuture = _fetchDailySales(
                            utcStartDate: utcStartDate!,
                            utcEndDate: utcEndDate!,
                          );
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text("Error: $e"),
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.lightGreenAccent,
                          content: Text(
                            "Record has been saved successfully",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
