class FindingItem {
  final String title;
  final String description;
  final int pageNum;
  final bool isThrilling;

  const FindingItem({
    required this.title,
    required this.description,
    required this.pageNum,
    this.isThrilling = false,
  });
}
