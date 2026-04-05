class SyncMarker {
  final int timeMs;
  final int page;
  final int lineIndex;

  SyncMarker({
    required this.timeMs,
    required this.page,
    required this.lineIndex,
  });

  factory SyncMarker.fromJson(Map<String, dynamic> json) {
    return SyncMarker(
      timeMs: json['timeMs'],
      page: json['page'],
      lineIndex: json['lineIndex'],
    );
  }
}
