import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/widgets/section_label.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<String> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version} (Build ${packageInfo.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    tooltip: 'Back',
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: SectionLabel('About'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('Mnemata', style: theme.textTheme.displaySmall),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(MnemataRadii.lg),
                  border: Border.all(color: cs.outline, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(MnemataRadii.lg),
                          child: Image.asset(
                            'assets/mnemata.jpg',
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Memory, kept.',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: cs.secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FutureBuilder<String>(
                                future: _getVersion(),
                                builder: (context, snapshot) {
                                  return Text(
                                    'Version ${snapshot.data ?? '...'}',
                                    style: theme.textTheme.mono(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      'A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Licenses'),
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Mnemata',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(MnemataRadii.md),
                          child: Image.asset(
                            'assets/mnemata.jpg',
                            height: 48,
                            width: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
