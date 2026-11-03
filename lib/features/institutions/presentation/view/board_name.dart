import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

String boardName(AppLocalizations l10n, Board board) => switch (board) {
  Board.cbse => l10n.boardCbse,
  Board.icse => l10n.boardIcse,
  Board.stateBoard => l10n.boardState,
  Board.ib => l10n.boardIb,
  Board.igcse => l10n.boardIgcse,
  Board.other => l10n.boardOther,
};
