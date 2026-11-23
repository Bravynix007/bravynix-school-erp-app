import 'package:bravynix_school_erp/app/app.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mocks.dart';

void main() {
  LinkedChild child(String id) =>
      LinkedChild(studentId: id, firstName: 'Diya', institutionName: 'Green Valley School', isBlocked: false);

  SessionState parentWith(List<LinkedChild> children) {
    final context = AuthContext(role: RoleCode.studentParent, children: children);
    return SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context));
  }

  test('a session read again with the same children, in new lists, is no change', () {
    expect(childrenChanged(parentWith([child('s1')]), parentWith([child('s1')])), isFalse);
  });

  test('a child added, removed or replaced is a change', () {
    expect(childrenChanged(parentWith([child('s1')]), parentWith([child('s1'), child('s2')])), isTrue);
    expect(childrenChanged(parentWith([child('s1'), child('s2')]), parentWith([child('s1')])), isTrue);
    expect(childrenChanged(parentWith([child('s1')]), parentWith([child('s2')])), isTrue);
  });

  test('signing out, or acting in a role with no children, is a change from having children', () {
    expect(childrenChanged(parentWith([child('s1')]), const SessionUnauthenticated()), isTrue);
    expect(childrenChanged(const SessionUnauthenticated(), const SessionUnauthenticated()), isFalse);
  });
}
