import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a due opens at its own location, with the id encoded', () {
    expect(AppRoutes.platformDue('d1'), '/platform-dues/d1');
    expect(AppRoutes.platformDue('a/b c'), '/platform-dues/a%2Fb%20c');
  });
}
