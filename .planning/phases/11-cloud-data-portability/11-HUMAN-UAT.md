---
status: diagnosed
phase: 11-cloud-data-portability
source: [11-VERIFICATION.md]
started: 2026-04-04T23:16:27Z
updated: 2026-04-05T19:13:53Z
---

## Current Test

[testing complete]

## Tests

### 1. Run manual cloud backup on a signed-in device from Settings
expected: Archive is created, upload succeeds to Google Drive, and success metadata updates in settings diagnostics
result: issue
reported: "No hay confirmación visible de creación/subida y no se puede verificar en app. Además restore solo acepta archivo local; debería listar backups de Drive y restaurar desde ahí."
severity: major

### 2. Leave app running through a due window with Wi-Fi/charging permutations
expected: Scheduler skips with deterministic reason codes when constraints fail and uploads when both constraints are met
result: skipped

## Summary

total: 2
passed: 0
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "Archive is created, upload succeeds to Google Drive, and success metadata updates in settings diagnostics"
	status: failed
	reason: "User reported: No hay confirmación visible de creación/subida y no se puede verificar en app. Además restore solo acepta archivo local; debería listar backups de Drive y restaurar desde ahí."
	severity: major
	test: 1
	root_cause: "El flujo de backup no expone una confirmación verificable más allá del snackbar transitorio y el flujo de restore está desacoplado de la nube: solo acepta ruta local manual en vez de listar backups remotos de Drive."
	artifacts:
		- path: "lib/features/settings/presentation/settings_screen.dart"
			issue: "El restore solicita path local manual y no ofrece selector desde Drive; feedback de backup no queda persistido/visible para validación de usuario."
		- path: "lib/features/backup/services/cloud_backup_provider.dart"
			issue: "Existe listBackups/downloadBackup pero no está integrado en UI de restore."
		- path: "lib/features/backup/services/backup_restore_service.dart"
			issue: "Aplica restore desde archivo local; falta entrada para restaurar desde bytes descargados de Drive."
	missing:
		- "Agregar pantalla/hoja de selección de backups remotos usando CloudBackupProvider.listBackups."
		- "Permitir descargar backup seleccionado desde Drive y ejecutar restore sin pedir ruta local manual."
		- "Persistir y mostrar en Settings estado verificable de último backup subido (id remoto/fecha/resultado) para feedback no transitorio."
	debug_session: ""
