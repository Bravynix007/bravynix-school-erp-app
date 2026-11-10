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
