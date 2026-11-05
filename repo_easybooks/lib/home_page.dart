import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===== Project color palette (same as Expenses/Income) =====
const _bg = Color(0xFF111719);
const _panel = Color(0xFF1C2729);
const _muted = Color(0xFFA6B7B4);
const _muted2 = Color(0xFFA6B7B4);
const _border = Color(0xFF334044);
const _text = Color(0xFFF0F5F3);
const _dim = Color(0xFFA6B7B4);
const _accent = Color(0xFF02D39A);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Helper: “nice” numbers for axis ticks (1–2–5 multiples)
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

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  final _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  final _numFmt = NumberFormat('#,##0');

  DateTime utcStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime utcEndDate = DateTime.now();

  late Future<List<dynamic>> salesFuture;
  late Future<List<dynamic>> expensesFuture;

  Future<List<dynamic>> _fetchSales() async {
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
      debugPrint('Error fetching total gross sales: $e');
      return <dynamic>[];
    }
  }

  Future<List<dynamic>> _fetchExpenses() async {
    try {
      final res = await supabase.rpc(
        'get_daily_expenses',
        params: {
          'start_date': utcStartDate.toIso8601String(),
          'end_date': utcEndDate.toIso8601String(),
          'tz': 'Asia/Manila',
        },
      );
      return (res is List) ? res : <dynamic>[];
    } catch (e) {
      debugPrint('Error fetching total expenses: $e');
      return <dynamic>[];
    }
  }

  Future<num> fetch_cmptd_total_gross_sales() async {
    final rows = await supabase
        .from('income')
        .select('total_gross_sales')
        .gte('created_at', utcStartDate.toIso8601String())
        .lt('created_at', utcEndDate.toIso8601String());
    final total = (rows as List)
        .map((e) => (e['total_gross_sales'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
    return total;
  }

  Future<num> fetch_cmptd_total_expenses() async {
    final rows = await supabase
        .from('expense')
        .select('total_expenses')
        .gte('created_at', utcStartDate.toIso8601String())
        .lt('created_at', utcEndDate.toIso8601String());

    final total = (rows as List)
        .map((e) => (e['total_expenses'] ?? 0) as num)
        .fold<num>(0, (a, b) => a + b);
    return total;
  }

  num show_total_gross_sales = 0;
  num show_total_expenses = 0;

  Future<void> _refreshData() async {
    final temp_total_gross_sales = await fetch_cmptd_total_gross_sales();
    final temp_total_expenses = await fetch_cmptd_total_expenses();
    setState(() {
      show_total_gross_sales = temp_total_gross_sales;
      show_total_expenses = temp_total_expenses;
    });
  }

  @override
  void initState() {
    super.initState();
    salesFuture = _fetchSales();
    expensesFuture = _fetchExpenses();
    _refreshData();
  }

  // Chart builder
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
          style: TextStyle(color: _dim),
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
        const Text(
          'Daily',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
                    const FlLine(color: Colors.white12, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white12),
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
                        style: const TextStyle(fontSize: 10, color: _dim),
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
                          style: const TextStyle(fontSize: 10, color: _dim),
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
                  dotData: const FlDotData(show: false),
                  color: _accent,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 450),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        '${DateFormat('MMM d, yyyy').format(utcStartDate.toLocal())} – ${DateFormat('MMM d, yyyy').format(utcEndDate.toLocal())}';

    Widget chartPanel(Future<List<dynamic>> future, String title, String key) {
      return _ChartCard(
        child: FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            final rows = snapshot.data ?? <dynamic>[];
            return buildDailyLineChart(
              context: context,
              rows: rows,
              title: title,
              valueKey: key,
            );
          },
        ),
      );
    }

    return Expanded(
      child: Container(
        color: _bg,
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: _bg,
                border: Border(bottom: BorderSide(color: _border)),
              ),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
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
                      setState(() {
                        utcStartDate = DateTime.utc(
                          picked.start.year,
                          picked.start.month,
                          picked.start.day,
                        );
                        utcEndDate = DateTime.utc(
                          picked.end.year,
                          picked.end.month,
                          picked.end.day,
                        );
                        salesFuture = _fetchSales();
                        expensesFuture = _fetchExpenses();
                      });
                      _refreshData();
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: const Text('Date range'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 740;
                  final sales = _KpiCard(
                    title: 'Gross sales',
                    icon: Icons.trending_up,
                    value: _money.format(show_total_gross_sales),
                  );
                  final expenses = _KpiCard(
                    title: 'Expenses',
                    icon: Icons.trending_down,
                    value: _money.format(show_total_expenses),
                  );
                  final profit = _KpiCard(
                    title: 'Gross profit',
                    icon: Icons.account_balance_wallet_outlined,
                    value: _money.format(
                      show_total_gross_sales - show_total_expenses,
                    ),
                    emphasis: true,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stacked) ...[
                          sales,
                          const SizedBox(height: 10),
                          expenses,
                          const SizedBox(height: 10),
                          profit,
                        ] else
                          Row(
                            children: [
                              Expanded(child: sales),
                              const SizedBox(width: 12),
                              Expanded(child: expenses),
                              const SizedBox(width: 12),
                              Expanded(child: profit),
                            ],
                          ),
                        const SizedBox(height: 18),
                        if (stacked) ...[
                          SizedBox(
                            height: 310,
                            child: chartPanel(
                              salesFuture,
                              'Gross sales',
                              'total_sales',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 310,
                            child: chartPanel(
                              expensesFuture,
                              'Expenses',
                              'total_expenses',
                            ),
                          ),
                        ] else
                          SizedBox(
                            height: 360,
                            child: Row(
                              children: [
                                Expanded(
                                  child: chartPanel(
                                    salesFuture,
                                    'Gross sales',
                                    'total_sales',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: chartPanel(
                                    expensesFuture,
                                    'Expenses',
                                    'total_expenses',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Supporting widgets ======

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.icon,
    required this.value,
    this.emphasis = false,
  });

  final String title;
  final IconData icon;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              Icon(
                icon,
                size: 17,
                color: emphasis ? _accent : _muted,
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasis ? _accent : _text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
