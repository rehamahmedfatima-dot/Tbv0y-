import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Flattens the habit_logs table (the most useful table to analyze
  /// externally) into a CSV file and opens the OS share sheet / browser
  /// download. Built entirely from in-memory bytes (no dart:io File) so
  /// this compiles and runs on web as well as mobile/desktop.
  static Future<void> exportHabitLogsAsCsv(List<dynamic> habitLogs) async {
    final rows = <List<dynamic>>[
      ['habit_id', 'log_date', 'completed', 'value', 'note'],
      for (final log in habitLogs)
        [
          log['habit_id'],
          log['log_date'],
          log['completed'],
          log['value'] ?? '',
          (log['note'] ?? '').toString().replaceAll('\n', ' '),
        ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(csv.codeUnits);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: 'tbvoy_habit_logs.csv', mimeType: 'text/csv')],
        text: 'My TBVOY habit history',
      ),
    );
  }

  /// Builds a simple, readable PDF summary of the export and shares it.
  static Future<void> exportSummaryAsPdf(Map<String, dynamic> data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('TBVOY — Your Data Export')),
          pw.SizedBox(height: 12),
          pw.Text('Generated on ${DateTime.now().toIso8601String().split('T').first}'),
          pw.SizedBox(height: 20),
          for (final entry in data.entries) ...[
            pw.Text(
              _titleCase(entry.key),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('${(entry.value as List).length} records'),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    final bytes = await doc.save();

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: 'tbvoy_data_summary.pdf', mimeType: 'application/pdf')],
        text: 'My TBVOY data summary',
      ),
    );
  }

  static String _titleCase(String s) =>
      s.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
