import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(MnemataRadii.sm),
        ),
      ),
    );
  }
}

class LabelSelectorSheet extends StatelessWidget {
  final MnemataItem item;

  const LabelSelectorSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MnemataItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LabelSelectorSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final database = GetIt.instance<AppDatabase>();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetDragHandle(),
            Text(
              'LABELS \u00B7 ASSIGN',
              style: theme.textTheme.tracked(cs.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign Labels',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, allLabelsSnapshot) {
                  if (!allLabelsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLabels = allLabelsSnapshot.data!;
                  if (allLabels.isEmpty) {
                    return Center(
                      child: Text(
                        'No labels created yet. Go to Label Manager to add some.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return StreamBuilder<List<Label>>(
                    stream: database.watchLabelsForItem(item.id),
                    builder: (context, itemLabelsSnapshot) {
                      final assignedLabelIds = (itemLabelsSnapshot.data ?? [])
                          .map((l) => l.id)
                          .toSet();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: allLabels.length,
                        itemBuilder: (context, index) {
                          final label = allLabels[index];
                          final isAssigned =
                              assignedLabelIds.contains(label.id);

                          return CheckboxListTile(
                            title: Text(
                              label.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                            secondary: Icon(
                              Icons.label,
                              color: label.color != null
                                  ? Color(label.color!)
                                  : cs.primary,
                            ),
                            value: isAssigned,
                            onChanged: (bool? value) {
                              if (value == true) {
                                database.assignLabelToItem(item.id, label.id);
                              } else {
                                database.removeLabelFromItem(
                                    item.id, label.id);
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulkLabelSelectorSheet extends StatelessWidget {
  final List<int> itemIds;

  const BulkLabelSelectorSheet({super.key, required this.itemIds});

  static Future<void> show(BuildContext context, List<int> itemIds) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BulkLabelSelectorSheet(itemIds: itemIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final database = GetIt.instance<AppDatabase>();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetDragHandle(),
            Text(
              'LABELS \u00B7 BULK ASSIGN',
              style: theme.textTheme.tracked(cs.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign Labels to ${itemIds.length} items',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, allLabelsSnapshot) {
                  if (!allLabelsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLabels = allLabelsSnapshot.data!;
                  if (allLabels.isEmpty) {
                    return Center(
                      child: Text(
                        'No labels created yet. Go to Label Manager to add some.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  // In bulk mode, we might not easily show "mixed" state natively without
                  // complex querying. Let's just show a clean list. If a user checks it,
                  // it adds to all. If they uncheck it, it removes from all.
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allLabels.length,
                    itemBuilder: (context, index) {
                      final label = allLabels[index];

                      return ListTile(
                        title: Text(
                          label.name,
                          style: theme.textTheme.bodyLarge,
                        ),
                        leading: Icon(
                          Icons.label,
                          color: label.color != null
                              ? Color(label.color!)
                              : cs.primary,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: cs.primary,
                              ),
                              onPressed: () {
                                database.assignLabelToItems(
                                    itemIds, label.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added label to items'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: cs.error,
                              ),
                              onPressed: () {
                                database.removeLabelFromItems(
                                    itemIds, label.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Removed label from items'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
