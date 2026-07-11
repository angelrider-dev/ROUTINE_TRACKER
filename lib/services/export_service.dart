import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';

/// Builds a JSON export of all tasks + completions and writes it to a
/// temp file, ready to hand to the OS share sheet.
///
/// HONEST SCOPE NOTE: this does NOT write to a "Downloads" folder — that
/// isn't a simple, reliable operation on iOS at all, and on Android it
/// needs scoped-storage/MediaStore handling that's a real feature in its
/// own right, not a one-line addition. Writing to a temp file and handing
/// it to the share sheet is the correct, honest mobile pattern: the user
/// picks where it actually ends up (Files, Drive, email, etc.).
class ExportService {
  Future<File> buildExportFile(List<RoutineTask> tasks, Map<String, bool> completions) async {
    final export = {
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'completions': completions,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(export);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'routine_tracker_export_$timestamp.json'));
    return file.writeAsString(jsonString);
  }
}
