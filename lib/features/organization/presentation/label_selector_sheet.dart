import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';

class LabelSelectorSheet extends StatelessWidget {
  final MnemataItem item;

  const LabelSelectorSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MnemataItem item) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LabelSelectorSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Labels',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Label>>(
              stream: database.watchAllLabels(),
              builder: (context, allLabelsSnapshot) {
                if (!allLabelsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLabels = allLabelsSnapshot.data!;
                if (allLabels.isEmpty) {
                  return const Center(child: Text('No labels created yet. Go to Label Manager to add some.'));
                }

                return StreamBuilder<List<Label>>(
                  stream: database.watchLabelsForItem(item.id),
                  builder: (context, itemLabelsSnapshot) {
                    final assignedLabelIds = (itemLabelsSnapshot.data ?? [])
                        .map((l) => l.id)
                        .toSet();

                    return ListView.builder(
                      itemCount: allLabels.length,
                      itemBuilder: (context, index) {
                        final label = allLabels[index];
                        final isAssigned = assignedLabelIds.contains(label.id);

                        return CheckboxListTile(
                          title: Text(label.name),
                          secondary: Icon(
                            Icons.label,
                            color: label.color != null ? Color(label.color!) : Colors.blue,
                          ),
                          value: isAssigned,
                          onChanged: (bool? value) {
                            if (value == true) {
                              database.assignLabelToItem(item.id, label.id);
                            } else {
                              database.removeLabelFromItem(item.id, label.id);
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
        ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BulkLabelSelectorSheet(itemIds: itemIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Labels to ${itemIds.length} items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Label>>(
              stream: database.watchAllLabels(),
              builder: (context, allLabelsSnapshot) {
                if (!allLabelsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLabels = allLabelsSnapshot.data!;
                if (allLabels.isEmpty) {
                  return const Center(child: Text('No labels created yet. Go to Label Manager to add some.'));
                }

                // In bulk mode, we might not easily show "mixed" state natively without
                // complex querying. Let's just show a clean list. If a user checks it,
                // it adds to all. If they uncheck it, it removes from all.
                return ListView.builder(
                  itemCount: allLabels.length,
                  itemBuilder: (context, index) {
                    final label = allLabels[index];

                    return ListTile(
                      title: Text(label.name),
                      leading: Icon(
                        Icons.label,
                        color: label.color != null ? Color(label.color!) : Colors.blue,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                            onPressed: () {
                              database.assignLabelToItems(itemIds, label.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added label to items')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              database.removeLabelFromItems(itemIds, label.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed label from items')),
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
        ],
      ),
    );
  }
}
