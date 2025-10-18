import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exports rows from a Supabase table to CSV and saves/downloads it.
/// Optional date filtering assumes your table has a `created_at` timestamp column.
/// Pass extra equality filters via `eq`, e.g. {'user_id': '<uid>'}.
Future<void> exportTableToCsv({
  required String table,
  String fileBaseName = 'export',
  String createdAtColumn = 'created_at',
  DateTime? startDate, // inclusive
  DateTime? endDate, // inclusive (whole day if only a date is provided)
  Map<String, dynamic>? eq, // e.g. {'user_id': '<uid>'}
}) async {
  final supa = Supabase.instance.client;

  // Build base query
  var baseQuery = supa.from(table).select();

  // Equality filters
  if (eq != null) {
    for (final entry in eq.entries) {
      baseQuery = baseQuery.eq(entry.key, entry.value);
    }
  }

  // Date range filters (if provided)
  if (startDate != null) {
    baseQuery = baseQuery.gte(
      createdAtColumn,
      startDate.toUtc().toIso8601String(),
    );
  }
  if (endDate != null) {
    // Make end-of-day inclusive by adding 1 day and using LT that next midnight
    final endExclusive = DateTime.utc(
      endDate.toUtc().year,
      endDate.toUtc().month,
      endDate.toUtc().day + 1,
    );
    baseQuery = baseQuery.lt(createdAtColumn, endExclusive.toIso8601String());
  }

  //  Create a new variable for sorted query
  final newQuery = baseQuery.order(createdAtColumn, ascending: true);

  // Fetch rows
  final rowsDynamic = await newQuery;

  // Handle no data case
  if (rowsDynamic is! List || rowsDynamic.isEmpty) {
    throw Exception('No records found to export.');
  }

  // Convert to List<Map<String, dynamic>>
  final list = rowsDynamic.cast<Map<String, dynamic>>();

  // Extract headers from first row
  final headers = list.first.keys.toList();

  // Build data rows (stringify everything)
  final dataRows = list.map((row) {
    return headers.map((h) {
      final val = row[h];
      if (val == null) return '';
      return val is String ? val : val.toString();
    }).toList();
  }).toList();

  // Convert to CSV string
  final csvString = const ListToCsvConverter().convert([headers, ...dataRows]);

  // Create filename like: expenses_2025-10-16T13-05-22.123Z.csv
  final nowIso = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final stamped = '${fileBaseName}_$nowIso';
  final bytes = Uint8List.fromList(utf8.encode(csvString));

  await FileSaver.instance.saveFile(
    name: stamped,
    bytes: bytes,
    fileExtension: 'csv',
    mimeType: MimeType.csv,
  );
}
