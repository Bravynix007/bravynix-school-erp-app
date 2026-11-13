import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_search_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds the card of one item. [busy]: a change to this item is on its way. [locked]: a change to any item is on its
/// way, so no card starts another.
typedef PagedItemBuilder<T> = Widget Function(BuildContext context, T item, {required bool busy, required bool locked});

/// The screen of a [PagedListBloc]: a search box, what [belowSearch] adds under it, and the pages read so far, with the
/// placeholder while it loads, the failed, forbidden and empty states, Load more, the outcome of a change above the list
/// and a snackbar for the item a change went through for. The pages of staff and of students are this widget with
/// their own cards and copy. Keys are `<keyPrefix>.search`, `.forbidden`, `.failed`, `.actionFailed`, `.moreFailed` and
/// `.more`.
class PagedListView<T> extends StatefulWidget {
  const new({
    required this.bloc,
    required this.keyPrefix,
    required this.searchHint,
    required this.searchClearTooltip,
    required this.loadMoreLabel,
    required this.errorText,
    required this.onRetry,
    required this.empty,
    required this.idOf,
    required this.itemBuilder,
    required this.changedMessage,
    this.belowSearch,
    this.leading,
    super.key,
  });

  final PagedListBloc<T> bloc;
  final String keyPrefix;
  final String searchHint;
  final String searchClearTooltip;
  final String loadMoreLabel;

  /// What a failure says.
  final String Function(ApiFailure failure) errorText;

  /// Try again after the first page failed.
  final VoidCallback onRetry;

  /// What an empty list says, for the search typed (empty for none).
  final Widget Function(BuildContext context, String query) empty;

  /// The ID a change names its item by (`PagedListLoaded.busyId`).
  final String Function(T item) idOf;
  final PagedItemBuilder<T> itemBuilder;

  /// What the snackbar says for the item a change went through for.
  final String Function(T changed) changedMessage;

  /// Under the search box, given whether the list is idle (no change is on its way).
  final Widget Function(BuildContext context, {required bool idle})? belowSearch;

  /// Above the cards of a list that has items, given whether the list is idle.
  final List<Widget> Function(BuildContext context, {required bool idle})? leading;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  /// The API takes 2 to 100 letters (API design 13.1); a pasted line is cut instead of refused.
  static const _maxSearch = 100;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = widget.bloc;
    final prefix = widget.keyPrefix;
    final below = widget.belowSearch;
    return BlocSelector<PagedListBloc<T>, PagedListState<T>, bool>(
      bloc: bloc,
      selector: (state) => switch (state) {
        PagedListLoaded<T>(:final busyId) => busyId == null,
        _ => true,
      },
      builder: (context, idle) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.sm, AppSpacing.screenMargin, 0),
            // The search waits while a change goes, so its outcome is not lost to a new list.
            child: AppSearchField(
              key: Key('$prefix.search'),
              controller: _search,
              hint: widget.searchHint,
              clearTooltip: widget.searchClearTooltip,
              enabled: idle,
              maxLength: _maxSearch,
              // The search is sent on the keyboard's search key, and cleared as soon as the box is emptied.
              onSubmitted: (text) => bloc.add(PagedListSearched(text)),
              onChanged: (text) {
                if (text.isEmpty) bloc.add(const PagedListSearched(''));
              },
            ),
          ),
          if (below != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.xs, AppSpacing.screenMargin, 0),
              child: below(context, idle: idle),
            ),
          Expanded(
            child: BlocConsumer<PagedListBloc<T>, PagedListState<T>>(
              bloc: bloc,
              listenWhen: (previous, current) => current is PagedListLoaded<T> && current.changed != null,
              listener: (context, state) {
                if (state is PagedListLoaded<T>) {
                  AppSnackbar.show(
                    context,
                    message: widget.changedMessage(state.changed as T),
                    kind: AppSnackbarKind.success,
                  );
                }
              },
              builder: (context, state) => switch (state) {
                PagedListLoading<T>() => SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 96]),
                PagedListFailed<T>(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: Key('$prefix.forbidden'),
                  title: widget.errorText(failure),
                ),
                PagedListFailed<T>(:final failure) => StatePanel.error(
                  key: Key('$prefix.failed'),
                  title: widget.errorText(failure),
                  actionLabel: l10n.retry,
                  onAction: widget.onRetry,
                ),
                PagedListLoaded<T>(:final items, :final query) when items.isEmpty => widget.empty(context, query),
                PagedListLoaded<T>() => _Items<T>(view: widget, state: state, idle: idle),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Items<T> extends StatelessWidget {
  const new({required this.view, required this.state, required this.idle});

  final PagedListView<T> view;
  final PagedListLoaded<T> state;
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefix = view.keyPrefix;
    final leading = view.leading;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (state.actionFailure case final failure?) ...[
          InlineMessage.error(view.errorText(failure), key: Key('$prefix.actionFailed')),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (leading != null) ...leading(context, idle: idle),
        for (final item in state.items) ...[
          view.itemBuilder(context, item, busy: state.busyId == view.idOf(item), locked: !idle),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.moreFailure case final failure?) ...[
          InlineMessage.error(view.errorText(failure), key: Key('$prefix.moreFailed')),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.hasMore)
          AppButton(
            key: Key('$prefix.more'),
            label: state.moreFailure == null ? view.loadMoreLabel : l10n.retry,
            variant: AppButtonVariant.secondary,
            loading: state.loadingMore,
            onPressed: idle ? () => view.bloc.add(const PagedListMoreRequested()) : null,
          ),
      ],
    );
  }
}
