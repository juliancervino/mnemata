import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ReaderScreen extends StatelessWidget {
  final MnemataItem item;

  const ReaderScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title ?? 'Article'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (item.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in Browser',
              onPressed: () async {
                await database.updateLastOpenedAt(item.id);
                final uri = Uri.parse(item.url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: item.content != null && item.content!.isNotEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title != null) ...[
                      Text(
                        item.title!,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    StreamBuilder<List<Label>>(
                      stream: database.watchLabelsForItem(item.id),
                      builder: (context, snapshot) {
                        final labels = snapshot.data ?? [];
                        if (labels.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: labels.map((label) => Chip(
                              label: Text(label.name, style: const TextStyle(fontSize: 12)),
                              backgroundColor: label.color != null ? Color(label.color!).withOpacity(0.2) : null,
                              side: BorderSide(color: label.color != null ? Color(label.color!) : Colors.blue),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )).toList(),
                          ),
                        );
                      },
                    ),
                    if (item.url != null) ...[
                      Text(
                        Uri.parse(item.url!).host,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(),
                    const SizedBox(height: 16),
                    HtmlWidget(
                      item.content!,
                      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                      onTapUrl: (url) async {
                        await database.updateLastOpenedAt(item.id);
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          return true;
                        }
                        return false;
                      },
                    ),
                    const SizedBox(height: 32), // Extra space at bottom
                  ],
                ),
              )
            : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No content extracted yet.'),
                  if (item.url != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await database.updateLastOpenedAt(item.id);
                        final uri = Uri.parse(item.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text('Open in Browser'),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}
