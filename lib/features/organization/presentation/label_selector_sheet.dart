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
