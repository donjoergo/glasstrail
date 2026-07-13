import 'dart:convert';

import 'package:file_selector/file_selector.dart';

class SelectedImportFile {
  const SelectedImportFile({required this.name, required this.contents});

  final String name;
  final String contents;
}

abstract class ImportFileService {
  const ImportFileService();

  Future<SelectedImportFile?> pickJsonFile();
}

String decodeImportFileContents(List<int> bytes) {
  try {
    return _stripLeadingBom(utf8.decode(bytes));
  } on FormatException {
    // Some export tools (older backups, Windows-authored files) write
    // Latin-1/Windows-1252 rather than UTF-8; falling back here means an
    // import doesn't fail outright just because of encoding, only if the
    // JSON itself is actually malformed.
    return _stripLeadingBom(latin1.decode(bytes));
  }
}

String _stripLeadingBom(String value) {
  // Some editors/tools prepend a UTF-8 byte-order-mark; left in place it
  // would break JSON parsing since it isn't valid at the start of a `{`.
  if (value.startsWith('\uFEFF')) {
    return value.substring(1);
  }
  return value;
}

class FileSelectorImportFileService extends ImportFileService {
  const FileSelectorImportFileService();

  @override
  Future<SelectedImportFile?> pickJsonFile() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'json', extensions: <String>['json']),
      ],
    );
    if (file == null) {
      return null;
    }

    return SelectedImportFile(
      name: file.name,
      contents: decodeImportFileContents(await file.readAsBytes()),
    );
  }
}
