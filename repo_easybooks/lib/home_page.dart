import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===== Project color palette (same as Expenses/Income) =====
const _bg = Color(0xFF161616);
const _panel = Color(0xFF1E1E1E);
const _muted = Color(0xFFA4A4A4);
const _muted2 = Color(0xFF9E9E9E);
const _border = Color(0xFF717171);
const _text = Colors.white;
const _dim = Color(0xFF9E9E9E);
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

  final List<Color> gradientColors = const [Color(0xFF232B6E), _accent];

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
                  dotData: const FlDotData(show: true),
                  color: _accent,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors
                          .map((c) => c.withOpacity(0.3))
                          .toList(),
                    ),
                  ),
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
        'Date Range: ${DateFormat('MMM d, yyyy').format(utcStartDate.toLocal())} → ${DateFormat('MMM d, yyyy').format(utcEndDate.toLocal())}';

    return Expanded(
      child: Container(
        color: _bg,
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
                          text: 'Home',
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

            // ==== Date Range Bar (below top bar) ====
            Container(
              height: 72,
              width: double.infinity,
              decoration: const BoxDecoration(color: _bg),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Range pill button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
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

                      // Update KPIs too
                      _refreshData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                        color: const Color(0xFF242424),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: _text,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pick Date Range',
                            style: TextStyle(color: _text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Current range label
                  Expanded(
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            title: 'Total Gross Sales',
                            icon: Icons.attach_money,
                            value: _money.format(show_total_gross_sales),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            title: 'Total Expenses',
                            icon: Icons.payment,
                            value: _money.format(show_total_expenses),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            title: 'Gross Profit',
                            icon: Icons.currency_exchange_outlined,
                            value: _money.format(
                              show_total_gross_sales - show_total_expenses,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Charts Row
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ChartCard(
                              child: FutureBuilder<List<dynamic>>(
                                future: salesFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const _Loading();
                                  }
                                  final rows = snapshot.data ?? <dynamic>[];
                                  return buildDailyLineChart(
                                    context: context,
                                    rows: rows,
                                    title: 'Total Gross Sales',
                                    valueKey: 'total_sales',
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ChartCard(
                              child: FutureBuilder<List<dynamic>>(
                                future: expensesFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const _Loading();
                                  }
                                  final rows = snapshot.data ?? <dynamic>[];
                                  return buildDailyLineChart(
                                    context: context,
                                    rows: rows,
                                    title: 'Total Expenses',
                                    valueKey: 'total_expenses',
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
  });

  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _accent.withOpacity(0.15),
            ),
            // ✅ uses the icon passed from parent
            child: Icon(icon, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: _dim, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
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
