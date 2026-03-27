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
                await _openItemUrl(context, database);
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Item'),
                    content: const Text('Are you sure you want to delete this item?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await database.deleteItem(item.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item deleted')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
                        _safeHost(item.url!),
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
                        await _openItemUrl(context, database);
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

  String _safeHost(String rawUrl) {
    final uri = _parseLaunchableUri(rawUrl);
    if (uri == null || uri.host.isEmpty) {
      return rawUrl;
    }
    return uri.host;
  }

  Uri? _parseLaunchableUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final direct = Uri.tryParse(trimmed);
    if (direct != null && direct.hasScheme) {
      return direct;
    }

    final withHttps = Uri.tryParse('https://$trimmed');
    return withHttps;
  }

  Future<void> _openItemUrl(BuildContext context, AppDatabase database) async {
    final rawUrl = item.url;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return;
    }

    final uri = _parseLaunchableUri(rawUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL')),
        );
      }
      return;
    }

    await database.updateLastOpenedAt(item.id);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open in browser')),
      );
    }
  }
}
