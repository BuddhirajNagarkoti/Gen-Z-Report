import 'package:flutter/foundation.dart';

abstract class PlatformFile {
  Future<bool> exists();
  Future<void> writeAsBytes(List<int> bytes);
  String get path;
}

abstract class PlatformDirectory {
  String get path;
  Future<bool> exists();
  Future<void> create({bool recursive = false});
}


