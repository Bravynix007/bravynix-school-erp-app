import 'package:flutter/material.dart';

enum AvatarSize {
  small(32),
  medium(40),
  large(56);

  new(this.dimension);

  final double dimension;
}

/// A round avatar: the photo when there is one, otherwise the person's
/// initials on the accent wash. The photo is passed as an [ImageProvider], so
/// tests and offline screens never touch the network.
class AppAvatar extends StatelessWidget {
  const new({required this.name, this.image, this.size = AvatarSize.medium, super.key});

  final String name;
  final ImageProvider? image;
  final AvatarSize size;

  /// "Asha Rao" gives AR; one word gives its first letter.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = size == AvatarSize.large
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.labelMedium;
    return Semantics(
      label: name,
      image: true,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: size.dimension / 2,
          backgroundColor: scheme.primaryContainer,
          foregroundImage: image,
          child: Text(initialsOf(name), style: textStyle?.copyWith(color: scheme.onPrimaryContainer)),
        ),
      ),
    );
  }
}
