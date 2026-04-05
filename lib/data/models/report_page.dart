class ReportPage {
  final int pageNumber;
  final String content;

  ReportPage({
    required this.pageNumber,
    required this.content,
  });

  factory ReportPage.fromJson(Map<String, dynamic> json) {
    return ReportPage(
      pageNumber: json['page'] as int,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'page': pageNumber,
    'content': content,
  };
}
