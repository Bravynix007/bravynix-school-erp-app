import 'package:flutter/widgets.dart';

/// Whether the person asked for less motion: Android's "remove animations"
/// (`disableAnimations`) or iOS's Reduce Motion (`accessibilityFeatures.reduceMotion`,
/// which `MediaQuery` does not fold into `disableAnimations`). Every animated
/// widget asks this one question.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) || View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
