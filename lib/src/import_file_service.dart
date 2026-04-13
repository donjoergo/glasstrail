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
    return _stripLeadingBom(latin1.decode(bytes));
  }
}

String _stripLeadingBom(String value) {
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
