import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/utils/private_storage_paths.dart';

/// The on-disk home of the diagnostics report.
///
/// The report lives in the private storage directory, which both platforms
/// exclude from backup, so breadcrumbs never leave the device in a backup.
///
/// Every write goes to a staging file that is then renamed over the report.
/// Writing the report in place truncates it first, so a process killed
/// mid-write (as when the app is swiped away right after the `detached`
/// breadcrumb) left an empty or partial file; the next launch could not parse
/// it and came back with collection off, since the opt-in lives in the same
/// file. A rename either fully happens or not at all, so the last complete
/// report survives. The sync and async paths stage to separate files because
/// a sync write can run while an async one is part-way through.
class DiagnosticsStorage {
  DiagnosticsStorage._(this._file);

  static const String fileName = 'endurain_diagnostics.json';
  static const String syncStagingSuffix = '.sync.tmp';
  static const String asyncStagingSuffix = '.async.tmp';

  final File _file;

  /// Opens the report under [supportDirectory]'s private directory, first
  /// moving a report an older version left directly in [supportDirectory]
  /// (which is backed up) into it.
  static DiagnosticsStorage open(Directory supportDirectory) {
    final separator = Platform.pathSeparator;
    final privateDirectory = Directory(
      '${supportDirectory.path}$separator$privateStorageDirectoryName',
    );
    if (!privateDirectory.existsSync()) {
      privateDirectory.createSync(recursive: true);
    }
    final file = File('${privateDirectory.path}$separator$fileName');
    _migrateLegacy(File('${supportDirectory.path}$separator$fileName'), file);
    return DiagnosticsStorage._(file);
  }

  static void _migrateLegacy(File legacy, File target) {
    try {
      if (legacy.existsSync()) {
        // A report already in the private directory is newer, so the old copy
        // is only dropped; either way it stops being backed up.
        if (!target.existsSync()) {
          try {
            legacy.renameSync(target.path);
          } on FileSystemException {
            target.writeAsStringSync(legacy.readAsStringSync(), flush: true);
            legacy.deleteSync();
          }
        } else {
          legacy.deleteSync();
        }
      }
      for (final suffix in [syncStagingSuffix, asyncStagingSuffix]) {
        final staging = File('${legacy.path}$suffix');
        if (staging.existsSync()) {
          staging.deleteSync();
        }
      }
    } catch (_) {
      // Best-effort: diagnostics must never surface I/O errors to the app.
    }
  }

  /// The stored payload, or an empty one when missing or unreadable.
  Map<String, Object?> readPayloadSync() {
    if (!_file.existsSync()) {
      return emptyPayload();
    }
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      return emptyPayload();
    }
    return emptyPayload();
  }

  static Map<String, Object?> emptyPayload() {
    return {
      'schemaVersion': 1,
      'app': 'Endurain',
      'breadcrumbs': <Object?>[],
      'errors': <Object?>[],
    };
  }

  static String encode(Map<String, Object?> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  /// Writes [content] synchronously (fsync).
  ///
  /// Used for errors, which must survive a hard crash, and for the opt-in and
  /// clear transitions, where a durable write is both cheap and expected.
  void writeSync(String content) {
    try {
      _staging(syncStagingSuffix)
        ..writeAsStringSync(content, flush: true)
        ..renameSync(_file.path);
    } catch (_) {
      // Best-effort: diagnostics must never surface I/O errors to the app.
    }
  }

  /// Writes [content] asynchronously, then publishes it unless [isStale]
  /// reports that a newer report was published during the write. The check and
  /// the rename run with no await between them, so nothing can land in
  /// between; the rename is a metadata change, cheap to block on.
  Future<void> writeAsync(
    String content, {
    required bool Function() isStale,
  }) async {
    try {
      final staging = _staging(asyncStagingSuffix);
      await staging.writeAsString(content, flush: true);
      if (isStale()) {
        return;
      }
      staging.renameSync(_file.path);
    } catch (_) {
      // Best-effort: diagnostics must never surface I/O errors to the app.
    }
  }

  /// Deletes the report and any staging file a killed write left behind.
  void deleteAll() {
    for (final target in [
      _file,
      _staging(syncStagingSuffix),
      _staging(asyncStagingSuffix),
    ]) {
      try {
        if (target.existsSync()) {
          target.deleteSync();
        }
      } catch (_) {
        // Best-effort: deletion failure must not surface to the app.
      }
    }
  }

  File _staging(String suffix) => File('${_file.path}$suffix');
}
