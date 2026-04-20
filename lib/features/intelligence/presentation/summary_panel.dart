import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';

class SummaryPanel extends StatefulWidget {
  const SummaryPanel({
    super.key,
    required this.item,
    required this.summaryService,
    this.loadSavedSummaryAction,
    this.generateSummaryAction,
    this.shareSummaryAction,
  });

  final MnemataItem item;
  final SummaryService summaryService;
  final Future<SummaryResult?> Function(MnemataItem item)? loadSavedSummaryAction;
  final Future<SummaryResult> Function(MnemataItem item, {bool forceRefresh})?
  generateSummaryAction;
  final Future<void> Function(String summaryText)? shareSummaryAction;

  @override
  State<SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends State<SummaryPanel> {
  bool _isLoading = false;
  SummaryResult? _result;

  @override
  void initState() {
    super.initState();
    _loadOrGenerate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(MnemataRadii.sm),
                ),
              ),
            ),
            // Kicker
            Text(
              'SUMMARY \u00B7 CLAUDE',
              style: theme.textTheme.tracked(cs.secondary),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              'AI Summary',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (_isLoading) const LinearProgressIndicator(),
            if (_result != null) ...[
              if (!_result!.isSuccess)
                Text(
                  _result!.guidance,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: cs.error,
                  ),
                )
              else ...[
                if (_result!.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Chip(
                      avatar: Icon(
                        Icons.save_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      label: const Text('Saved summary'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Text(
                  'TL;DR',
                  style: theme.textTheme.tracked(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  _result!.tldr,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'KEY POINTS',
                  style: theme.textTheme.tracked(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                ..._result!.keyPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '\u2022 $point',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'WHY IT MATTERS',
                  style: theme.textTheme.tracked(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  _result!.whyItMatters,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _regenerate,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canShareSummary ? _shareSummary : null,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerate() async {
    await _runGeneration(forceRefresh: true);
  }

  Future<void> _loadOrGenerate() async {
    setState(() {
      _isLoading = true;
    });

    final saved = await (widget.loadSavedSummaryAction?.call(widget.item) ??
      widget.summaryService.loadSavedSummary(widget.item));
    if (saved != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _result = saved;
      });
      return;
    }

    final result = await (widget.generateSummaryAction?.call(widget.item) ??
      widget.summaryService.generateSummary(widget.item));

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  Future<void> _runGeneration({required bool forceRefresh}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await (widget.generateSummaryAction?.call(
          widget.item,
          forceRefresh: forceRefresh,
        ) ??
        widget.summaryService.generateSummary(
          widget.item,
          forceRefresh: forceRefresh,
        ));

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  bool get _canShareSummary {
    final result = _result;
    return result != null && result.isSuccess && result.tldr.trim().isNotEmpty;
  }

  Future<void> _shareSummary() async {
    final result = _result;
    if (result == null || !result.isSuccess) {
      return;
    }

    final summaryText = _buildSummaryText(result);
    if (summaryText.trim().isEmpty) {
      return;
    }

    await (widget.shareSummaryAction?.call(summaryText) ??
        ShareUtils.shareSummary(
          item: widget.item,
          summaryText: summaryText,
        ));
  }

  String _buildSummaryText(SummaryResult result) {
    final buffer = StringBuffer()
      ..writeln('*TL;DR*')
      ..writeln(result.tldr.trim());
    final keyPoints = result.keyPoints
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList(growable: false);
    if (keyPoints.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('*Key points*');
      for (final point in keyPoints) {
        buffer.writeln('- $point');
      }
    }
    final why = result.whyItMatters.trim();
    if (why.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('*Why it matters*')
        ..writeln(why);
    }
    return buffer.toString().trim();
  }
}
