import 'package:file_selector/file_selector.dart';

abstract class PhotoService {
  const PhotoService();

  Future<String?> pickImage();
}

class FileSelectorPhotoService extends PhotoService {
  const FileSelectorPhotoService();

  @override
  Future<String?> pickImage() async {
    final image = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'images',
          extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
    return image?.path;
  }
}
