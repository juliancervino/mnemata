// SectionLabel — Mnemata
//
// Uppercase mono "tracked" label for grouping list sections
// (e.g. "TODAY · APR 16", "EARLIER THIS WEEK").
//
// Uses the `tracked()` TextTheme extension defined in
// `lib/core/theme/app_theme.dart`, so the label stays in sync with the
// current theme's onSurfaceVariant color.

import 'package:flutter/material.dart';

import 'package:mnemata/core/theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.tracked(color ?? cs.onSurfaceVariant),
    );
  }
}
