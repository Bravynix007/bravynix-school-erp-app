import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/l10n/app_language.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionBloc(getIt<AuthRepository>())..add(const SessionStarted()),
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
  late final SessionChanges _sessionChanges = SessionChanges(context.read<SessionBloc>().stream);
  late final GoRouter _router = createRouter(context.read<SessionBloc>(), changes: _sessionChanges);
  late final StreamSubscription<ApiFailure> _updates;

  @override
  void initState() {
    super.initState();
    _updates = getIt<ApiEvents>().updateRequired.listen((_) => _router.go(AppRoutes.updateRequired));
  }

  @override
  void dispose() {
    unawaited(_updates.cancel());
    _router.dispose();
    _sessionChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (previous, current) => current is SessionAuthenticated,
      // Messages from the API follow the person's language once signed in (PRD 11.3).
      listener: (context, state) =>
          getIt<AppLanguage>().use((state as SessionAuthenticated).session.person.preferredLanguage),
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
