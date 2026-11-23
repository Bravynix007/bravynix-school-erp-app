import 'package:equatable/equatable.dart';

/// One page of a list the API pages (API design 7.4): the [items] of [page], and how many pages there are.
class ItemsPage<T> extends Equatable {
  const new(this.items, {required this.page, required this.totalPages});

  final List<T> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, totalPages];
}

/// Every item of a list the API pages: [read] is called for page 1, 2, and so on until the last page has been read.
Future<List<T>> allPages<T>(Future<ItemsPage<T>> Function(int page) read) async {
  final all = <T>[];
  for (var page = 1; ; page++) {
    final answer = await read(page);
    all.addAll(answer.items);
    if (!answer.hasMore) return all;
  }
}
