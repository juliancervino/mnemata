import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoTagDomain;
  late bool _autoTagYear;
  final SettingsService _settingsService = GetIt.instance<SettingsService>();

  @override
  void initState() {
    super.initState();
    _autoTagDomain = _settingsService.autoTagDomain;
    _autoTagYear = _settingsService.autoTagYear;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ingestion Options',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Auto-tag by domain'),
            subtitle: const Text('Automatically assign a tag based on the URL domain (e.g. elpais.com)'),
            value: _autoTagDomain,
            onChanged: (value) {
              setState(() {
                _autoTagDomain = value;
              });
              _settingsService.setAutoTagDomain(value);
            },
          ),
          SwitchListTile(
            title: const Text('Auto-tag by year'),
            subtitle: const Text('Automatically assign a tag with the current year (e.g. 2026)'),
            value: _autoTagYear,
            onChanged: (value) {
              setState(() {
                _autoTagYear = value;
              });
              _settingsService.setAutoTagYear(value);
            },
          ),
        ],
      ),
    );
  }
}
