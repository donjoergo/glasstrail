import 'dart:io';

// MapLibre's native platform views are only integrated for Android/iOS in
// this app; desktop targets (macOS/Windows/Linux) fall through to false
// here even though dart:io is available there too, since no MapLibre
// platform implementation is wired up for them.
bool get isMapLibrePlatformSupported => Platform.isAndroid || Platform.isIOS;
