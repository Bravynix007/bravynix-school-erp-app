import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allPages', () {
    test('reads page after page until the last, and returns every item in order', () async {
      final asked = <int>[];
      final all = await allPages<String>((page) async {
        asked.add(page);
        return ItemsPage(['p$page'], page: page, totalPages: 3);
      });
      expect(all, ['p1', 'p2', 'p3']);
      expect(asked, [1, 2, 3]);
    });

    test('reads a list of one page once', () async {
      var reads = 0;
      final all = await allPages<int>((page) async {
        reads++;
        return const ItemsPage([1, 2], page: 1, totalPages: 1);
      });
      expect(all, [1, 2]);
      expect(reads, 1);
    });

    test('passes a refusal on, whichever page it comes on', () async {
      await expectLater(
        allPages<int>((page) async {
          if (page == 2) throw StateError('refused');
          return ItemsPage([page], page: page, totalPages: 2);
        }),
        throwsStateError,
      );
    });
  });
}
