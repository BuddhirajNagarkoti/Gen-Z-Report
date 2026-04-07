import 'platform_io_interface.dart';

class WebFile implements PlatformFile {
  final String _path;
  WebFile(this._path);

  @override
  Future<bool> exists() => Future.value(false);

  @override
  Future<void> writeAsBytes(List<int> bytes) => Future.value();

  @override
  String get path => _path;
}

class WebDirectory implements PlatformDirectory {
  final String _path;
  WebDirectory(this._path);

  @override
  String get path => _path;

  @override
  Future<bool> exists() => Future.value(false);

  @override
  Future<void> create({bool recursive = false}) => Future.value();
}

PlatformFile createPlatformFile(String path) => WebFile(path);
PlatformDirectory createPlatformDirectory(String path) => WebDirectory(path);
