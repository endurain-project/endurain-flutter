import 'dart:io';

import 'package:endurain/core/utils/id_generation.dart';

class ActivityGpxFileWriter {
  ActivityGpxFileWriter({
    Future<Directory> Function()? temporaryDirectoryProvider,
    String Function()? uniqueSuffixProvider,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? (() async => Directory.systemTemp),
       _uniqueSuffixProvider = uniqueSuffixProvider ?? uniqueSuffix;

  static const String filePrefix = 'endurain_activity_';
  static const String fileExtension = '.gpx';

  final Future<Directory> Function() _temporaryDirectoryProvider;
  final String Function() _uniqueSuffixProvider;

  Future<File> writeGpx(String gpx) async {
    final directory = await _temporaryDirectoryProvider();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '$filePrefix${_uniqueSuffixProvider()}$fileExtension',
    );
    return file.writeAsString(gpx, flush: true);
  }

  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
