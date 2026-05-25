import '_helpers.dart';

class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final bool hasNextPage;
  final String? nextCursor;
  final bool? hasMore;

  Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNextPage,
    this.nextCursor,
    this.hasMore,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final rawData = json['data'];
    final List<T> items = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(parseItem)
            .toList()
        : <T>[];
    final pagination =
        (json['pagination'] as Map<String, dynamic>?) ?? const {};
    return Paginated<T>(
      items: items,
      page: intFromJson(pagination['page'], 1),
      limit: intFromJson(pagination['limit'], items.length),
      total: intFromJson(pagination['total'], items.length),
      hasNextPage: boolFromJson(pagination['hasNextPage']),
      nextCursor: pagination['nextCursor']?.toString(),
      hasMore: pagination['hasMore'] is bool
          ? pagination['hasMore'] as bool
          : null,
    );
  }
}
