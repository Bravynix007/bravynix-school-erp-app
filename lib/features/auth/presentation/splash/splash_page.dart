import 'dart:math' as math;

import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown while the stored session is checked, and when that check could not
/// reach the server (the app is online only, system design 7).
class SplashPage extends StatelessWidget {
  const new({super.key});

  static const double _brandTopPadding = AppSpacing.xxl * 2 + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionBloc>().state;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthColors.brand,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Align(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 380,
                    minHeight: (viewport.maxHeight - AppSpacing.xl * 2).clamp(0, double.infinity),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 296,
                        child: CustomPaint(
                          painter: _OrbitPainter(),
                          child: Padding(
                            padding: EdgeInsets.only(top: _brandTopPadding, bottom: AppSpacing.lg),
                            child: AuthWordmark(inverse: true, centered: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      if (state case SessionRestoreFailed(:final failure))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthHeading(title: l10n.authRestoreTitle, inverse: true),
                            const SizedBox(height: AppSpacing.md),
                            InlineMessage.error(loginErrorText(l10n, failure)),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              key: const Key('splash.retry'),
                              label: l10n.retry,
                              icon: Icons.refresh,
                              onPressed: () => context.read<SessionBloc>().add(const SessionStarted()),
                            ),
                          ],
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 232),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.authCheckingSession,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AuthColors.onBrandMuted),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              LinearProgressIndicator(
                                semanticsLabel: l10n.loading,
                                color: AuthColors.gold,
                                backgroundColor: AuthColors.progressTrack,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuthColors.ornament
      ..style = PaintingStyle.stroke;
    // Centre the motif behind the tile, above the wordmark.
    final centre = Offset(size.width / 2, SplashPage._brandTopPadding + 50);
    final orbit = Rect.fromCenter(center: Offset.zero, width: math.min(size.width, 260), height: 104);
    for (final angle in [-31, 18, 62]) {
      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..rotate(angle * math.pi / 180)
        ..drawOval(orbit, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => false;
}
