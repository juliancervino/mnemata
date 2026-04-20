import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mnemata/core/database/tables.dart';

part 'app_database.g.dart';

class SemanticChunkInput {
  const SemanticChunkInput({
    required this.chunkIndex,
    required this.text,
    required this.embeddingVectorJson,
  });

  final int chunkIndex;
  final String text;
  final String embeddingVectorJson;
}

@DriftDatabase(
  tables: [
    MnemataItems,
    Labels,
    ItemLabels,
    SummaryCaches,
    SemanticIndexStates,
    SemanticChunks,
    AnnotationRecords,
  ],
  include: {'tables.drift'},
)
class AppDatabase extends _$AppDatabase {
  static const String databaseName = 'mnemata_db';

  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  Future<void> _createPerformanceIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_item_labels_item_id ON item_labels(item_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_item_labels_label_id ON item_labels(label_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_mnemata_items_last_opened_at ON mnemata_items(last_opened_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_mnemata_items_sort_order ON mnemata_items(sort_order)',
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createPerformanceIndexes();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(mnemataItems, mnemataItems.content);
          await m.create(mnemataSearch);
        }
        if (from < 3) {
          await m.addColumn(mnemataItems, mnemataItems.lastOpenedAt);
          await m.createTable(labels);
          await m.createTable(itemLabels);
        }
        if (from < 4) {
          await m.addColumn(mnemataItems, mnemataItems.thumbnailUrl);
        }
        if (from < 5) {
          await m.addColumn(mnemataItems, mnemataItems.sortOrder);
        }
        if (from < 6) {
          await _createPerformanceIndexes();
        }
        if (from < 7) {
          await m.createTable(summaryCaches);
          await m.createTable(semanticIndexStates);
          await m.createTable(semanticChunks);
          await m.createTable(annotationRecords);
        }
        if (from < 8) {
          await m.addColumn(mnemataItems, mnemataItems.author);
        }
        if (from < 9) {
          await m.addColumn(mnemataItems, mnemataItems.deletedAt);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: databaseName,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  Stream<List<MnemataItem>> watchAllItems() {
    return (select(mnemataItems)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<MnemataItem>> watchRecycleBinItems() {
    return (select(mnemataItems)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<MnemataItem>> watchRecentlyOpened(int limit) {
    return (select(mnemataItems)
          ..where((t) => t.lastOpenedAt.isNotNull() & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.lastOpenedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<MnemataItem>> watchRecentlyOpenedByLabel(int labelId, int limit) {
    final query =
        select(mnemataItems).join([
            innerJoin(itemLabels, itemLabels.itemId.equalsExp(mnemataItems.id)),
          ])
          ..where(
            itemLabels.labelId.equals(labelId) &
                mnemataItems.lastOpenedAt.isNotNull() &
                mnemataItems.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm(
              expression: mnemataItems.lastOpenedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(mnemataItems)).toList();
    });
  }

  Future<int> insertItem(MnemataItemsCompanion item) {
    return into(mnemataItems).insert(item);
  }

  Future<MnemataItem?> getItemByUrl(String url) {
    return (select(mnemataItems)
          ..where((t) => t.url.equals(url) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<MnemataItem?> getItemByCanonicalUrl(String rawUrl) async {
    final candidates = _buildUrlLookupCandidates(rawUrl);
    if (candidates.isEmpty) return null;

    final placeholders = List<String>.filled(candidates.length, '?').join(', ');
    final rows = await customSelect(
      'SELECT * FROM mnemata_items '
      'WHERE deleted_at IS NULL AND url IS NOT NULL AND LOWER(url) IN ($placeholders) '
      'LIMIT 1',
      variables: [
        for (final candidate in candidates)
          Variable<String>(candidate.toLowerCase()),
      ],
      readsFrom: {mnemataItems},
    ).get();

    if (rows.isEmpty) return null;
    return mnemataItems.map(rows.first.data);
  }

  Future<MnemataItem?> getItemByFilePath(String filePath) {
    return (select(mnemataItems)
          ..where((t) => t.filePath.equals(filePath) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<MnemataItem>> getActiveUrlItems() {
    return (select(mnemataItems)
          ..where(
            (t) =>
                t.deletedAt.isNull() & t.type.equals('url') & t.url.isNotNull(),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> markItemDeletedAt(int id, DateTime deletedAt) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(deletedAt: Value(deletedAt.toUtc())),
    );
  }

  Future<int> deleteItem(int id) {
    return markItemDeletedAt(id, DateTime.now());
  }

  Future<int> deleteItems(List<int> ids) {
    if (ids.isEmpty) {
      return Future<int>.value(0);
    }

    return (update(mnemataItems)..where((t) => t.id.isIn(ids))).write(
      MnemataItemsCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<int> restoreItemFromRecycle(int id) {
    return (update(mnemataItems)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNotNull()))
        .write(const MnemataItemsCompanion(deletedAt: Value(null)));
  }

  Future<int> permanentlyDeleteItem(int id) {
    return transaction(() async {
      await (delete(annotationRecords)..where((t) => t.itemId.equals(id))).go();
      await (delete(semanticChunks)..where((t) => t.itemId.equals(id))).go();
      await (delete(
        semanticIndexStates,
      )..where((t) => t.itemId.equals(id))).go();
      await (delete(summaryCaches)..where((t) => t.itemId.equals(id))).go();
      await (delete(itemLabels)..where((t) => t.itemId.equals(id))).go();
      return (delete(mnemataItems)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<int> permanentlyDeleteItems(List<int> ids) {
    if (ids.isEmpty) {
      return Future<int>.value(0);
    }

    return transaction(() async {
      await (delete(annotationRecords)..where((t) => t.itemId.isIn(ids))).go();
      await (delete(semanticChunks)..where((t) => t.itemId.isIn(ids))).go();
      await (delete(
        semanticIndexStates,
      )..where((t) => t.itemId.isIn(ids))).go();
      await (delete(summaryCaches)..where((t) => t.itemId.isIn(ids))).go();
      await (delete(itemLabels)..where((t) => t.itemId.isIn(ids))).go();
      return (delete(mnemataItems)..where((t) => t.id.isIn(ids))).go();
    });
  }

  Future<int> purgeRecycleBinBefore(
    DateTime cutoff, {
    int batchSize = 200,
  }) async {
    final purgedCount = await transaction(() async {
      final idsToDelete =
          await (select(mnemataItems)
                ..where((t) => t.deletedAt.isSmallerThanValue(cutoff.toUtc()))
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.deletedAt,
                    mode: OrderingMode.asc,
                  ),
                ])
                ..limit(batchSize))
              .map((row) => row.id)
              .get();

      if (idsToDelete.isEmpty) {
        return 0;
      }

      await (delete(
        annotationRecords,
      )..where((t) => t.itemId.isIn(idsToDelete))).go();
      await (delete(
        semanticChunks,
      )..where((t) => t.itemId.isIn(idsToDelete))).go();
      await (delete(
        semanticIndexStates,
      )..where((t) => t.itemId.isIn(idsToDelete))).go();
      await (delete(
        summaryCaches,
      )..where((t) => t.itemId.isIn(idsToDelete))).go();
      await (delete(itemLabels)..where((t) => t.itemId.isIn(idsToDelete))).go();
      return (delete(mnemataItems)..where((t) => t.id.isIn(idsToDelete))).go();
    });

    return purgedCount;
  }

  Future<void> updateItemContent(
    int id,
    String content,
    String? title,
    String? thumbnailUrl, {
    String? author,
  }) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(
        content: Value(content),
        title: title != null ? Value(title) : const Value.absent(),
        author: author != null ? Value(author) : const Value.absent(),
        thumbnailUrl: thumbnailUrl != null
            ? Value(thumbnailUrl)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateLastOpenedAt(int id) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(lastOpenedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateItemDetails(
    int id,
    String title,
    String? url,
    String? author,
  ) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(
        title: Value(title),
        url: url != null ? Value(url) : const Value.absent(),
        author: author != null ? Value(author) : const Value.absent(),
      ),
    );
  }

  Future<void> updateItemSortOrder(int id, int newOrder) {
    return (update(mnemataItems)..where((t) => t.id.equals(id))).write(
      MnemataItemsCompanion(sortOrder: Value(newOrder)),
    );
  }

  // Label Operations
  Future<int> insertLabel(LabelsCompanion label) => into(labels).insert(label);
  Future<bool> updateLabel(LabelsCompanion label) =>
      update(labels).replace(label);
  Future<int> deleteLabel(int id) =>
      (delete(labels)..where((t) => t.id.equals(id))).go();

  Future<Label?> getLabelByName(String name) {
    return (select(
      labels,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<int> getOrCreateLabel(String name, {int? color}) async {
    final existing = await getLabelByName(name);
    if (existing != null) {
      return existing.id;
    }
    return await insertLabel(
      LabelsCompanion.insert(
        name: name,
        color: Value(color),
        isFolder: const Value(false),
      ),
    );
  }

  Stream<List<Label>> watchAllLabels() {
    return (select(
      labels,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  // Item Label Operations
  Future<void> assignLabelToItem(int itemId, int labelId) {
    return into(itemLabels).insert(
      ItemLabelsCompanion.insert(itemId: itemId, labelId: labelId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> assignLabelToItems(List<int> itemIds, int labelId) async {
    await batch((b) {
      for (final itemId in itemIds) {
        b.insert(
          itemLabels,
          ItemLabelsCompanion.insert(itemId: itemId, labelId: labelId),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<int> removeLabelFromItem(int itemId, int labelId) {
    return (delete(
      itemLabels,
    )..where((t) => t.itemId.equals(itemId) & t.labelId.equals(labelId))).go();
  }

  Future<int> removeLabelFromItems(List<int> itemIds, int labelId) {
    return (delete(
      itemLabels,
    )..where((t) => t.itemId.isIn(itemIds) & t.labelId.equals(labelId))).go();
  }

  Future<int> clearLabelsForItem(int itemId) {
    return (delete(itemLabels)..where((t) => t.itemId.equals(itemId))).go();
  }

  Stream<List<Label>> watchLabelsForItem(int itemId) {
    final query = select(labels).join([
      innerJoin(itemLabels, itemLabels.labelId.equalsExp(labels.id)),
    ])..where(itemLabels.itemId.equals(itemId));

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(labels)).toList();
    });
  }

  Stream<Map<int, List<Label>>> watchLabelsForItems(List<int> itemIds) {
    if (itemIds.isEmpty) {
      return Stream.value(const {});
    }

    final query = select(labels).join([
      innerJoin(itemLabels, itemLabels.labelId.equalsExp(labels.id)),
    ])..where(itemLabels.itemId.isIn(itemIds));

    return query.watch().map((rows) {
      final result = <int, List<Label>>{};
      for (final row in rows) {
        final itemId = row.readTable(itemLabels).itemId;
        final label = row.readTable(labels);
        result.putIfAbsent(itemId, () => <Label>[]).add(label);
      }
      return result;
    });
  }

  Stream<List<MnemataItem>> watchItemsByLabel(int labelId) {
    final query =
        select(mnemataItems).join([
            innerJoin(itemLabels, itemLabels.itemId.equalsExp(mnemataItems.id)),
          ])
          ..where(
            itemLabels.labelId.equals(labelId) &
                mnemataItems.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm(
              expression: mnemataItems.createdAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(mnemataItems)).toList();
    });
  }

  Future<void> updateItemsSortOrderInBatch(
    List<MnemataItem> orderedItems,
  ) async {
    await batch((b) {
      for (var i = 0; i < orderedItems.length; i++) {
        b.update(
          mnemataItems,
          MnemataItemsCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(orderedItems[i].id),
        );
      }
    });
  }

  Future<void> upsertSummaryCache({
    required int itemId,
    required String contentHash,
    required String tldr,
    required List<String> keyPoints,
    required String whyItMatters,
  }) async {
    final existing =
        await (select(summaryCaches)..where(
              (t) =>
                  t.itemId.equals(itemId) & t.contentHash.equals(contentHash),
            ))
            .getSingleOrNull();

    final companion = SummaryCachesCompanion(
      itemId: Value(itemId),
      contentHash: Value(contentHash),
      tldr: Value(tldr),
      keyPointsJson: Value(keyPoints.join('\n')),
      whyItMatters: Value(whyItMatters),
      createdAt: Value(DateTime.now().toUtc()),
    );

    if (existing == null) {
      await into(summaryCaches).insert(companion);
      return;
    }

    await (update(
      summaryCaches,
    )..where((t) => t.id.equals(existing.id))).write(companion);
  }

  Future<SummaryCache?> getSummaryCache({
    required int itemId,
    required String contentHash,
  }) {
    return (select(summaryCaches)..where(
          (t) => t.itemId.equals(itemId) & t.contentHash.equals(contentHash),
        ))
        .getSingleOrNull();
  }

  Future<void> upsertSemanticIndexMetadata({
    required int itemId,
    required String contentHash,
    required String embeddingModel,
    required int chunkCount,
  }) async {
    final existing = await (select(
      semanticIndexStates,
    )..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
    final companion = SemanticIndexStatesCompanion(
      itemId: Value(itemId),
      contentHash: Value(contentHash),
      embeddingModel: Value(embeddingModel),
      chunkCount: Value(chunkCount),
      indexedAt: Value(DateTime.now().toUtc()),
    );
    if (existing == null) {
      await into(semanticIndexStates).insert(companion);
      return;
    }
    await (update(
      semanticIndexStates,
    )..where((t) => t.id.equals(existing.id))).write(companion);
  }

  Future<void> replaceSemanticChunks({
    required int itemId,
    required List<SemanticChunkInput> chunks,
  }) async {
    await transaction(() async {
      await (delete(
        semanticChunks,
      )..where((t) => t.itemId.equals(itemId))).go();
      if (chunks.isEmpty) {
        return;
      }
      await batch((b) {
        for (final chunk in chunks) {
          b.insert(
            semanticChunks,
            SemanticChunksCompanion.insert(
              itemId: itemId,
              chunkIndex: chunk.chunkIndex,
              chunkText: chunk.text,
              embeddingVectorJson: chunk.embeddingVectorJson,
            ),
          );
        }
      });
    });
  }

  Future<List<SemanticChunk>> readSemanticChunks(int itemId) {
    return (select(semanticChunks)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm(expression: t.chunkIndex)]))
        .get();
  }

  Future<List<SemanticChunk>> listAllSemanticChunks() {
    return (select(semanticChunks)..orderBy([
          (t) => OrderingTerm(expression: t.itemId),
          (t) => OrderingTerm(expression: t.chunkIndex),
        ]))
        .get();
  }

  Future<SemanticIndexState?> readSemanticIndexState(int itemId) {
    return (select(
      semanticIndexStates,
    )..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
  }

  Future<List<MnemataItem>> getItemsByIds(List<int> itemIds) async {
    if (itemIds.isEmpty) {
      return const <MnemataItem>[];
    }

    final rows = await (select(
      mnemataItems,
    )..where((t) => t.id.isIn(itemIds))).get();
    final byId = <int, MnemataItem>{for (final row in rows) row.id: row};
    return itemIds
        .where(byId.containsKey)
        .map((id) => byId[id]!)
        .toList(growable: false);
  }

  Future<List<Label>> getLabelsByNames(List<String> names) async {
    if (names.isEmpty) {
      return const <Label>[];
    }

    final normalized = names
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return const <Label>[];
    }

    final allLabels = await watchAllLabels().first;
    return allLabels
        .where((label) => normalized.contains(label.name.trim().toLowerCase()))
        .toList(growable: false);
  }

  Future<int> insertAnnotation({
    required int itemId,
    required String quoteText,
    required String anchorJson,
    String? note,
  }) {
    return into(annotationRecords).insert(
      AnnotationRecordsCompanion.insert(
        itemId: itemId,
        quoteText: quoteText,
        anchorJson: anchorJson,
        note: Value(note),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<List<AnnotationRecord>> listAnnotationsForItem(int itemId) {
    return (select(annotationRecords)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> updateAnnotation({
    required int annotationId,
    required String quoteText,
    required String anchorJson,
    String? note,
  }) {
    return (update(
      annotationRecords,
    )..where((t) => t.id.equals(annotationId))).write(
      AnnotationRecordsCompanion(
        quoteText: Value(quoteText),
        anchorJson: Value(anchorJson),
        note: Value(note),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> deleteAnnotation(int annotationId) {
    return (delete(
      annotationRecords,
    )..where((t) => t.id.equals(annotationId))).go();
  }

  Stream<List<MnemataItem>> watchItemsByMultipleLabels(List<int> labelIds) {
    if (labelIds.isEmpty) return watchAllItems();
    if (labelIds.length == 1) return watchItemsByLabel(labelIds.first);

    // SQL for "AND" logic: items that have all selected labels.
    final query = customSelect(
      'SELECT i.* FROM mnemata_items i '
      'INNER JOIN item_labels il ON il.item_id = i.id '
      'WHERE i.deleted_at IS NULL '
      'AND il.label_id IN (${labelIds.join(',')}) '
      'GROUP BY i.id '
      'HAVING COUNT(DISTINCT il.label_id) = ${labelIds.length} '
      'ORDER BY i.sort_order ASC, i.created_at DESC',
      readsFrom: {mnemataItems, itemLabels},
    );

    return query.watch().map((rows) {
      return rows.map((row) => mnemataItems.map(row.data)).toList();
    });
  }

  Stream<List<MnemataItem>> searchItems(
    String query, {
    List<int> labelIds = const [],
  }) {
    if (labelIds.isEmpty) {
      return customSelect(
        'SELECT i.* FROM mnemata_items i '
        'INNER JOIN mnemata_search s ON s.rowid = i.id '
        'WHERE i.deleted_at IS NULL AND mnemata_search MATCH ?',
        variables: [Variable(query)],
        readsFrom: {mnemataItems, mnemataSearch},
      ).watch().map((rows) {
        return rows.map((row) => mnemataItems.map(row.data)).toList();
      });
    }

    final placeholders = List.filled(labelIds.length, '?').join(',');
    final variables = [
      Variable(query),
      ...labelIds.map((id) => Variable(id)),
      Variable(labelIds.length),
    ];

    return customSelect(
      'SELECT DISTINCT i.* FROM mnemata_items i '
      'INNER JOIN mnemata_search s ON s.rowid = i.id '
      'WHERE i.deleted_at IS NULL AND mnemata_search MATCH ? '
      'AND i.id IN ('
      '  SELECT item_id FROM item_labels '
      '  WHERE label_id IN ($placeholders) '
      '  GROUP BY item_id '
      '  HAVING COUNT(DISTINCT label_id) = ?'
      ')',
      variables: variables,
      readsFrom: {mnemataItems, mnemataSearch, itemLabels},
    ).watch().map((rows) {
      return rows.map((row) => mnemataItems.map(row.data)).toList();
    });
  }

  Set<String> _buildUrlLookupCandidates(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return <String>{};

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return <String>{trimmed};
    }

    final normalized = _normalizeUrlForLookup(parsed);
    final withSlash = _normalizePathSlash(normalized, withTrailingSlash: true);
    final withoutSlash = _normalizePathSlash(
      normalized,
      withTrailingSlash: false,
    );

    return <String>{trimmed, normalized, withSlash, withoutSlash};
  }

  String _normalizeUrlForLookup(Uri parsed) {
    final scheme = parsed.scheme.toLowerCase();
    final host = parsed.host.toLowerCase();
    final path = parsed.path.isEmpty ? '/' : parsed.path;
    final query = parsed.hasQuery ? '?${parsed.query}' : '';
    return '$scheme://$host$path$query';
  }

  String _normalizePathSlash(
    String normalizedUrl, {
    required bool withTrailingSlash,
  }) {
    final parsed = Uri.tryParse(normalizedUrl);
    if (parsed == null) return normalizedUrl;

    final currentPath = parsed.path.isEmpty ? '/' : parsed.path;
    final updatedPath = withTrailingSlash
        ? (currentPath.endsWith('/') ? currentPath : '$currentPath/')
        : (currentPath.length > 1 && currentPath.endsWith('/')
              ? currentPath.substring(0, currentPath.length - 1)
              : currentPath);

    final query = parsed.hasQuery ? '?${parsed.query}' : '';
    return '${parsed.scheme}://${parsed.host}$updatedPath$query';
  }
}
