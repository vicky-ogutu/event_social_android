class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pages;
  final int total;

  bool get hasMore => page < pages;
}
