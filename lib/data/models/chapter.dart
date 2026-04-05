class Chapter {
  final String id;
  final String title;
  final int startPage;
  final int? endPage;
  final List<Chapter> sections;

  Chapter({
    required this.id,
    required this.title,
    required this.startPage,
    this.endPage,
    this.sections = const [],
  });

  String getDisplayTitle([bool _ = false]) => title;
}
