import 'dart:io' as io;
import 'platform_io_interface.dart';

class MobileFile implements PlatformFile {
  final io.File _file;
  MobileFile(String path) : _file = io.File(path);

  @override
  Future<bool> exists() => _file.exists();

  @override
  Future<void> writeAsBytes(List<int> bytes) => _file.writeAsBytes(bytes);

  @override
  String get path => _file.path;
}

class MobileDirectory implements PlatformDirectory {
  final io.Directory _dir;
  MobileDirectory(String path) : _dir = io.Directory(path);

  @override
  String get path => _dir.path;

  @override
  Future<bool> exists() => _dir.exists();

  @override
  Future<void> create({bool recursive = false}) => _dir.create(recursive: recursive);
}

PlatformFile createPlatformFile(String path) => MobileFile(path);
PlatformDirectory createPlatformDirectory(String path) => MobileDirectory(path);
