import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';

class SummaryPanel extends StatefulWidget {
  const SummaryPanel({
    super.key,
    required this.item,
    required this.summaryService,
  });

  final MnemataItem item;
  final SummaryService summaryService;

  @override
  State<SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends State<SummaryPanel> {
  bool _isLoading = false;
  SummaryResult? _result;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _result?.isSuccess == true
                        ? 'Regenerate summary'
                        : 'Generate summary',
                  ),
                ),
                if (_result?.isSuccess == true)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _regenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Force refresh'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            if (_result != null) ...[
              if (!_result!.isSuccess)
                Text(
                  _result!.guidance,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else ...[
                if (_result!.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Chip(
                      avatar: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Saved summary'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Text('TL;DR', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(_result!.tldr),
                const SizedBox(height: 10),
                Text(
                  'Key Points',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ..._result!.keyPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $point'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Why it matters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(_result!.whyItMatters),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
    });

    final result = await widget.summaryService.generateSummary(widget.item);

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  Future<void> _regenerate() async {
    setState(() {
      _isLoading = true;
    });

    final result = await widget.summaryService.generateSummary(
      widget.item,
      forceRefresh: true,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  Future<void> _loadSaved() async {
    setState(() {
      _isLoading = true;
    });

    final saved = await widget.summaryService.loadSavedSummary(widget.item);

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = saved;
    });
  }
}
