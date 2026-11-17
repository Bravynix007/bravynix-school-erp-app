import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/l10n/app_language.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/storage/child_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/push/domain/push_messaging.dart';
import 'package:bravynix_school_erp/features/push/domain/push_registrar.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SessionBloc(getIt<AuthRepository>())..add(const SessionStarted())),
        // Above the router, so every screen a parent opens reads the same child.
        BlocProvider(create: (_) => ActiveChildBloc(getIt<ChildChoiceStore>())),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const new({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final SessionBloc _session = context.read<SessionBloc>();
  late final SessionChanges _sessionChanges = SessionChanges(_session.stream);
  late final GoRouter _router = createRouter(_session, changes: _sessionChanges);
  late final StreamSubscription<ApiFailure> _updates;
  late final StreamSubscription<String> _pushTokens;

  @override
  void initState() {
    super.initState();
    _updates = getIt<ApiEvents>().updateRequired.listen((_) => _router.go(AppRoutes.updateRequired));
    _pushTokens = getIt<PushMessaging>().tokenRefreshes.listen((_) {
      if (_session.state is SessionAuthenticated) unawaited(getIt<PushRegistrar>().register());
    });
  }

  @override
  void dispose() {
    unawaited(_updates.cancel());
    unawaited(_pushTokens.cancel());
    _router.dispose();
    _sessionChanges.dispose();
    super.dispose();
  }

  /// The children a parent guards in the role they are acting in; none for any other role or when signed out.
  static List<LinkedChild> _childrenOf(SessionState state) =>
      state is SessionAuthenticated ? state.session.activeContext?.children ?? const [] : const [];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => current is SessionAuthenticated,
          // Messages from the API follow the person's language once signed in (PRD 11.3).
          listener: (context, state) =>
              getIt<AppLanguage>().use((state as SessionAuthenticated).session.person.preferredLanguage),
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => current is SessionAuthenticated,
          // Alerts need this install's push token on the server, before a role is chosen too (ME-04).
          listener: (context, state) => unawaited(getIt<PushRegistrar>().register()),
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) => _childrenOf(previous) != _childrenOf(current),
          listener: (context, state) =>
              context.read<ActiveChildBloc>().add(ActiveChildChildrenChanged(_childrenOf(state))),
        ),
      ],
      child: ValueListenableBuilder<String>(
        valueListenable: getIt<AppLanguage>(),
        builder: (context, language, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          theme: AppTheme.light(),
          routerConfig: _router,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => SnackbarEscape(child: child!),
        ),
      ),
    );
  }
}
