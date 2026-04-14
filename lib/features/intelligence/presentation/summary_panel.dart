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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate summary'),
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
}
