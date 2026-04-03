import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Future<void> shareItem(BuildContext context, MnemataItem item) async {
    bool includeContent = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Share Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Include downloaded content'),
                    value: includeContent,
                    onChanged: (value) {
                      setState(() {
                        includeContent = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('SHARE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _executeShare(item, includeContent);
    }
  }

  static Future<void> _executeShare(MnemataItem item, bool includeContent) async {
    final String title = item.title ?? 'Article';
    String host = '';
    
    if (item.url != null) {
      try {
        final uri = Uri.parse(item.url!);
        host = uri.host.replaceFirst('www.', '');
        
        // Archive logic
        if (host.startsWith('archive.') || host == 'archive.today' || host == 'archive.ph' || host == 'archive.is' || host == 'archive.li' || host == 'archive.vn') {
          final segments = uri.pathSegments;
          for (final segment in segments.reversed) {
            if (segment.contains('.')) {
              try {
                final potentialUri = Uri.parse(segment.startsWith('http') ? segment : 'https://$segment');
                if (potentialUri.host.isNotEmpty) {
                  host = potentialUri.host.replaceFirst('www.', '');
                  break;
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    String shareText = '*$title*';
    if (host.isNotEmpty) shareText += '\n_${host}_';
    if (item.url != null) shareText += '\n\nSource: ${item.url}';
    
    if (includeContent && item.content != null && item.content!.isNotEmpty) {
      // Convert HTML to WhatsApp-compatible markdown
      String plainText = item.content!
          .replaceAll(RegExp(r'<(strong|b)>'), '*')
          .replaceAll(RegExp(r'<\/(strong|b)>'), '*')
          .replaceAll(RegExp(r'<(em|i)>'), '_')
          .replaceAll(RegExp(r'<\/(em|i)>'), '_')
          .replaceAll(RegExp(r'<(br|br \/)>'), '\n')
          .replaceAll(RegExp(r'<\/(p|div|h[1-6])>'), '\n\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      
      // Removed truncation as requested
      shareText += '\n\n---\n\n$plainText';
    }
    
    await Share.share(shareText, subject: item.title);
  }
}
