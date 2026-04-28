import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/ingestion/services/web_file_validation.dart';

class WebIngestFile {
  WebIngestFile({
    required this.name,
    required this.bytes,
    this.mimeType,
    int? sizeInBytes,
  }) : sizeInBytes = sizeInBytes ?? bytes.lengthInBytes;

  final String name;
  final Uint8List bytes;
  final String? mimeType;
  final int sizeInBytes;
}

typedef WebIngestFilePicker = Future<WebIngestFile?> Function();
typedef WebIngestUrlSubmitter = Future<void> Function(String url);
typedef WebIngestFileSubmitter = Future<void> Function(WebIngestFile file);

class WebAddItemSheet extends StatefulWidget {
  const WebAddItemSheet({
    super.key,
    this.pickFile,
    this.onSubmitUrl,
    this.onSubmitFile,
    this.enableDragAndDrop = true,
    this.closeOnSubmit = true,
  });

  final WebIngestFilePicker? pickFile;
  final WebIngestUrlSubmitter? onSubmitUrl;
  final WebIngestFileSubmitter? onSubmitFile;
  final bool enableDragAndDrop;
  final bool closeOnSubmit;

  @override
  State<WebAddItemSheet> createState() => _WebAddItemSheetState();
}

class _WebAddItemSheetState extends State<WebAddItemSheet> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _obsidianController = TextEditingController();

  DropzoneViewController? _dropzoneController;
  bool _isDropHovering = false;
  bool _isSubmitting = false;

  String? _urlError;
  String? _fileError;
  String? _obsidianError;
  WebIngestFile? _selectedFile;

  @override
  void dispose() {
    _urlController.dispose();
    _obsidianController.dispose();
    super.dispose();
  }

  WebIngestUrlSubmitter _resolveUrlSubmitter() {
    final submitter = widget.onSubmitUrl;
    if (submitter != null) {
      return submitter;
    }

    return (url) => GetIt.instance<ShareService>().handleUrl(url);
  }

  WebIngestFileSubmitter _resolveFileSubmitter() {
    final submitter = widget.onSubmitFile;
    if (submitter != null) {
      return submitter;
    }

    return (file) => GetIt.instance<ShareService>().handleManualFileIngest(
          fileName: file.name,
          bytes: file.bytes,
          mimeType: file.mimeType,
        );
  }

  Future<WebIngestFile?> _defaultFilePicker() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: WebFileValidation.supportedExtensions.toList(),
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      return null;
    }

    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      return null;
    }

    return WebIngestFile(
      name: file.name,
      bytes: bytes,
      mimeType: file.extension,
      sizeInBytes: file.size,
    );
  }

  Future<void> _pickFile() async {
    final picker = widget.pickFile ?? _defaultFilePicker;
    final file = await picker();
    if (file == null || !mounted) {
      return;
    }

    _acceptIncomingFile(file);
  }

  Future<void> _handleDrop(dynamic event) async {
    final controller = _dropzoneController;
    if (controller == null) {
      return;
    }

    final name = await controller.getFilename(event);
    final mimeType = await controller.getFileMIME(event);
    final bytes = await controller.getFileData(event);
    if (!mounted) {
      return;
    }

    _acceptIncomingFile(
      WebIngestFile(
        name: name,
        bytes: bytes,
        mimeType: mimeType,
      ),
    );
  }

  void _acceptIncomingFile(WebIngestFile file) {
    final validationError = WebFileValidation.validate(
      fileName: file.name,
      sizeInBytes: file.sizeInBytes,
    );

    setState(() {
      if (validationError != null) {
        _selectedFile = null;
        _fileError = validationError;
        return;
      }

      _selectedFile = file;
      _fileError = null;
    });
  }

  Future<void> _submitUrl() async {
    final url = _urlController.text.trim();
    if (!WebFileValidation.isSupportedUrl(url)) {
      setState(() {
        _urlError = WebFileValidation.invalidUrlMessage;
      });
      return;
    }

    setState(() {
      _urlError = null;
    });

    await _runSubmit(() => _resolveUrlSubmitter()(url));
  }

  Future<void> _submitFile() async {
    final file = _selectedFile;
    if (file == null) {
      setState(() {
        _fileError = 'Select a supported file to continue.';
      });
      return;
    }

    final validationError = WebFileValidation.validate(
      fileName: file.name,
      sizeInBytes: file.sizeInBytes,
    );

    if (validationError != null) {
      setState(() {
        _fileError = validationError;
      });
      return;
    }

    setState(() {
      _fileError = null;
    });

    await _runSubmit(() => _resolveFileSubmitter()(file));
  }

  Future<void> _runSubmit(Future<void> Function() action) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.closeOnSubmit && mounted) {
        Navigator.of(context).pop();
        await Future<void>.delayed(Duration.zero);
      }
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  Widget _buildDropTarget(ThemeData theme, ColorScheme cs) {
    final borderColor = _isDropHovering ? cs.primary : cs.outlineVariant;
    final fillColor = _isDropHovering
        ? cs.secondaryContainer
        : cs.surfaceContainerLow;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(MnemataRadii.lg),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Drag and drop a file here',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Supported: PDF, MD, JPG, JPEG, PNG, WEBP up to 25 MB',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (!kIsWeb || !widget.enableDragAndDrop) {
      return content;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(MnemataRadii.lg),
      child: Stack(
        children: [
          content,
          Positioned.fill(
            child: DropzoneView(
              onCreated: (controller) {
                _dropzoneController = controller;
              },
              onDrop: _handleDrop,
              onHover: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isDropHovering = true;
                });
              },
              onLeave: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _isDropHovering = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTab(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com/article',
            ),
            onSubmitted: (_) {
              _submitUrl();
            },
          ),
          if (_urlError != null) ...[
            const SizedBox(height: 8),
            Text(
              _urlError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.error,
              ),
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitUrl,
            icon: const Icon(Icons.add_link),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTab(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropTarget(theme, cs),
          const SizedBox(height: 12),
          if (_selectedFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(MnemataRadii.md),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          _formatFileSize(_selectedFile!.sizeInBytes),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_fileError != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.error,
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose File'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add File'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitObsidian() async {
    final content = _obsidianController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _obsidianError = 'Please paste the Obsidian Web Clipper content.';
      });
      return;
    }

    setState(() {
      _obsidianError = null;
    });

    await _runSubmit(() => GetIt.instance<ShareService>().handleManualPaste(
          content,
          url: '', // Will be extracted from frontmatter if possible
        ));
  }

  Widget _buildObsidianTab(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _obsidianController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: 'Obsidian Clipping',
                hintText: '---\ntitle: "Example"\nauthor: "[[Author]]"\n---\nContent...',
                alignLabelWithHint: true,
                errorText: _obsidianError,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitObsidian,
            icon: const Icon(Icons.note_add),
            label: const Text('Add Clipping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SizedBox(
          height: 600,
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(MnemataRadii.full),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ADD ITEM',
                  style: theme.textTheme.tracked(cs.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add from URL, file, or Obsidian',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TabBar(
                  tabs: const [
                    Tab(text: 'URL'),
                    Tab(text: 'File'),
                    Tab(text: 'Obsidian'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUrlTab(theme, cs),
                      _buildFileTab(theme, cs),
                      _buildObsidianTab(theme, cs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}