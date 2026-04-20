import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/chronological_list/services/search_snippet_builder.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.title,
    required this.source,
    required this.snippet,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String source;
  final SearchSnippet snippet;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleText = title.trim().isEmpty ? 'Untitled item' : title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(MnemataRadii.lg)),
        child: InkWell(
          borderRadius: const BorderRadius.all(
            Radius.circular(MnemataRadii.lg),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (snippet.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                            children: [
                              for (final segment in snippet.segments)
                                TextSpan(
                                  text: segment.text,
                                  style: segment.highlighted
                                      ? TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        )
                                      : null,
                                ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
