import 'package:flutter/material.dart';

enum ItemQuickAction { openReader, toggleRead, toggleFavorite, delete, share }

class ItemQuickActionsMenu extends StatelessWidget {
  const ItemQuickActionsMenu({
    super.key,
    required this.isRead,
    required this.isFavorite,
    required this.onSelected,
  });

  final bool isRead;
  final bool isFavorite;
  final ValueChanged<ItemQuickAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<ItemQuickAction>(
      tooltip: 'Item actions',
      icon: const Icon(Icons.more_horiz),
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem<ItemQuickAction>(
          value: ItemQuickAction.openReader,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.chrome_reader_mode_outlined),
            title: Text('Open Reader'),
          ),
        ),
        PopupMenuItem<ItemQuickAction>(
          value: ItemQuickAction.toggleRead,
          child: ListTile(
            dense: true,
            leading: Icon(
              isRead
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
            title: Text(isRead ? 'Mark as Unread' : 'Mark as Read'),
          ),
        ),
        PopupMenuItem<ItemQuickAction>(
          value: ItemQuickAction.toggleFavorite,
          child: ListTile(
            dense: true,
            leading: Icon(
              isFavorite ? Icons.favorite_outline : Icons.favorite_border,
            ),
            title: Text(isFavorite ? 'Unfavorite' : 'Favorite'),
          ),
        ),
        PopupMenuItem<ItemQuickAction>(
          value: ItemQuickAction.delete,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text('Delete', style: TextStyle(color: cs.error)),
          ),
        ),
        const PopupMenuItem<ItemQuickAction>(
          value: ItemQuickAction.share,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.share_outlined),
            title: Text('Share'),
          ),
        ),
      ],
    );
  }
}
