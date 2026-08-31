import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../services/export_service.dart';
import '../services/update_service.dart';
import '../services/google_drive_service.dart';
import 'design_playground_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _canCheckBiometrics = false;
  bool _checkingForUpdates = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  BackupInfo? _backupInfo;
  String _currentVersion = '1.0.4';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadCurrentVersion();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final info = await _driveService.getBackupInfo();
    if (mounted) {
      setState(() {
        _backupInfo = info;
      });
    }
  }

  Future<void> _loadCurrentVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) {
      setState(() {
        _currentVersion = version;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (!mounted) return;

      setState(() {
        _checkingForUpdates = false;
      });

      if (updateInfo == null) {
        UpdateService.showErrorDialog(context);
      } else if (updateInfo.updateAvailable) {
        UpdateService.showUpdateDialog(context, updateInfo);
      } else {
        UpdateService.showUpToDateDialog(context, updateInfo.currentVersion);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
        UpdateService.showErrorDialog(context);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _biometricService.isAvailable();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = available;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canCheckBiometrics = false;
        });
      }
    }
  }

  Future<void> _toggleBiometricLock(bool enable, MoneyProvider provider) async {
    if (enable) {
      // Verify biometric before enabling
      try {
        final didAuthenticate = await _biometricService.authenticate(
          localizedReason: 'Verify your identity to enable biometric lock',
          biometricOnly: false,
        );

        if (didAuthenticate) {
          await provider.setBiometricLock(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric lock enabled'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enable: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await provider.setBiometricLock(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric lock disabled')),
        );
      }
    }
  }

  Future<void> _backupToGoogleDrive() async {
    setState(() => _isBackingUp = true);

    try {
      // Get data from provider (includes Firebase data for logged-in users)
      final provider = Provider.of<MoneyProvider>(context, listen: false);
      final result = await _driveService.backupToGoogleDrive(
        transactions: provider.transactions,
        loans: provider.loans,
        goals: provider.goals,
        accounts: provider.accounts,
      );

      if (mounted) {
        setState(() => _isBackingUp = false);

        if (result.success) {
          await _loadBackupInfo(); // Refresh backup info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.message} (${result.itemCount} items)'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromGoogleDrive() async {
    // Show confirmation dialog
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Restore from Google Drive?',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will replace all your current data with the backup.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              if (_backupInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup Info:',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_backupInfo!.modifiedTime != null)
                        Text(
                          'Date: ${DateFormat('MMM d, yyyy h:mm a').format(_backupInfo!.modifiedTime!)}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
              ),
              child: Text('Restore', style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );

    if (shouldRestore != true) return;

    setState(() => _isRestoring = true);

    try {
      final result = await _driveService.restoreFromGoogleDrive();

      if (mounted) {
        setState(() => _isRestoring = false);

        if (result.success) {
          // Reload provider data
          final provider = Provider.of<MoneyProvider>(context, listen: false);

          // For logged-in users, import restored Hive data to Firebase
          // This ensures transactions go to the right place
          await provider.importRestoredDataToFirebase();

          // Reload all data
          await provider.reloadData();

          // Force UI update after restore
          // Force UI update check handled by reloadData

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.message} (${result.itemCount} items restored)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData(String format) async {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final exportService = ExportService();

    try {
      String? filePath;
      if (format == 'CSV') {
        filePath = await exportService.exportToCSV(provider.transactions);
      } else if (format == 'PDF') {
        filePath = await exportService.exportToPDF(
          provider.transactions,
          currencySymbol: provider.currencySymbol,
        );
      } else if (format == 'JSON') {
        filePath = await exportService.exportToJSON(provider.transactions);
      }

      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported to: PennyWise folder\n$filePath'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Export failed: Storage permission denied or error occurred',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final exportService = ExportService();

    try {
      // Pick file
      final file = await exportService.pickImportFile();
      if (file == null) {
        return; // User cancelled
      }

      if (file.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not access file path'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Determine file type and import
      ImportResult result;
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'csv') {
        result = await exportService.importFromCSV(
          file.path!,
          userId: provider.userId,
        );
      } else if (extension == 'json') {
        result = await exportService.importFromJSON(
          file.path!,
          userId: provider.userId,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported file format. Use CSV or JSON.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (result.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errors.isNotEmpty
                    ? 'Import failed: ${result.errors.first}'
                    : 'No transactions found in file',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show preview dialog
      if (mounted) {
        final shouldImport = await _showImportPreviewDialog(result);
        if (shouldImport == true) {
          // Import transactions
          int imported = 0;
          for (final transaction in result.transactions) {
            try {
              await provider.addTransaction(transaction);
              imported++;
            } catch (e) {
              debugPrint('Failed to import transaction: $e');
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported $imported transactions'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showImportPreviewDialog(ImportResult result) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isLight = theme.brightness == Brightness.light;
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: isLight
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: theme.dividerColor, width: 1.5),
                )
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            'Import Preview',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${result.successfulRows} of ${result.totalRows} transactions',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
                if (result.hasErrors) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${result.errors.length} rows had errors',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Preview:',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.transactions.length > 5
                        ? 5
                        : result.transactions.length,
                    itemBuilder: (context, index) {
                      final t = result.transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              t.isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: t.isExpense ? Colors.red : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${t.isExpense ? '-' : '+'}${t.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: t.isExpense ? Colors.red : Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (result.transactions.length > 5) ...[
                  const SizedBox(height: 8),
                  Text(
                    '... and ${result.transactions.length - 5} more',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
              ),
              child: Text('Import ${result.transactions.length}', style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildUpdateTile(),
          const SizedBox(height: 24),

          _buildSection('Security'),
          _buildSwitchTile(
            'Biometric Lock',
            _canCheckBiometrics
                ? 'Require fingerprint or face to open app'
                : 'Not available on this device',
            Icons.fingerprint,
            provider.biometricLockEnabled,
            _canCheckBiometrics
                ? (value) => _toggleBiometricLock(value, provider)
                : null,
          ),
          const SizedBox(height: 24),

          _buildSection('Data'),
          _buildActionTile(
            'Import Transactions',
            'Import from CSV or JSON file',
            Icons.file_upload,
            _importData,
          ),
          _buildActionTile(
            'Export to CSV',
            'Download transaction history',
            Icons.file_download,
            () => _exportData('CSV'),
          ),
          _buildActionTile(
            'Export to JSON',
            'Export as JSON file',
            Icons.code,
            () => _exportData('JSON'),
          ),
          _buildActionTile(
            'Export to PDF',
            'Generate PDF report',
            Icons.picture_as_pdf,
            () => _exportData('PDF'),
          ),
          const SizedBox(height: 24),

          _buildSection('Google Drive Sync'),
          _buildGoogleDriveBackupTile(),
          _buildGoogleDriveRestoreTile(),
          const SizedBox(height: 24),
          _buildSection('Developer'),
          _buildActionTile(
            'Design Playground',
            'Preview card designs',
            Icons.palette,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DesignPlaygroundScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('About'),
          _buildInfoTile('Version', _currentVersion),
          _buildInfoTile('Developer', 'Dark'),
        ],
      ),
    );
  }

  Widget _buildUpdateTile() {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return GestureDetector(
      onTap: _checkingForUpdates ? null : _checkForUpdates,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAmoled || isLight
              ? Colors.transparent
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight
                ? Colors.black
                : (isAmoled
                      ? Colors.white
                      : Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.black.withOpacity(0.05)
                    : (isAmoled
                          ? Colors.transparent
                          : Theme.of(context).primaryColor.withOpacity(0.1)),
                shape: BoxShape.circle,
                border: isAmoled
                    ? Border.all(color: Colors.white.withOpacity(0.2))
                    : null,
              ),
              child: Icon(
                Icons.system_update,
                color: isLight
                    ? Colors.black
                    : (isAmoled
                          ? Colors.white
                          : Theme.of(context).primaryColor),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check for Updates',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black
                          : Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: v$_currentVersion',
                    style: TextStyle(
                      color: isLight
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_checkingForUpdates)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLight
                        ? Colors.black
                        : (isAmoled
                              ? Colors.white
                              : Theme.of(context).primaryColor),
                  ),
                ),
              )
            else
              Icon(
                Icons.refresh,
                color: isLight
                    ? Colors.black
                    : (isAmoled
                          ? Colors.white
                          : Theme.of(context).primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isLight
              ? Colors.black
              : (isAmoled ? Colors.white : Theme.of(context).primaryColor),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAmoled || isLight
              ? Colors.transparent
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isLight
              ? Border.all(color: Colors.black)
              : (isAmoled ? Border.all(color: Colors.white) : null),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLight
                  ? Colors.black
                  : (isAmoled ? Colors.white : Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLight
                          ? Colors.black
                          : Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled ? Colors.transparent : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isLight
            ? Border.all(color: Colors.black)
            : (isAmoled ? Border.all(color: Colors.white) : null),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isLight
                  ? Colors.black
                  : (isAmoled
                        ? Colors.white
                        : Theme.of(context).textTheme.titleMedium?.color),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isLight
                  ? Colors.black.withOpacity(0.7)
                  : (isAmoled
                        ? Colors.white70
                        : Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6)),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    void Function(bool)? onChanged,
  ) {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAmoled ? Colors.transparent : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isLight
            ? Border.all(color: Colors.black)
            : (isAmoled ? Border.all(color: Colors.white) : null),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isLight
                ? Colors.black
                : (isAmoled ? Colors.white : Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLight
                        ? Colors.black
                        : Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: isAmoled
                ? Colors.white
                : Theme.of(context).primaryColor,
            activeTrackColor: isAmoled
                ? Colors.white.withOpacity(0.3)
                : (isLight ? Colors.black.withOpacity(0.3) : null),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleDriveBackupTile() {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return GestureDetector(
      onTap: _isBackingUp ? null : _backupToGoogleDrive,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAmoled ? Colors.transparent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight
                ? Colors.black
                : (isAmoled ? Colors.white : Colors.blue.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAmoled
                    ? Colors.transparent
                    : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isAmoled
                    ? Border.all(color: Colors.white.withOpacity(0.2))
                    : null,
              ),
              child: Icon(
                Icons.cloud_upload,
                color: isLight
                    ? Colors.black
                    : (isAmoled ? Colors.white : Colors.blue),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup to Google Drive',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _backupInfo != null && _backupInfo!.modifiedTime != null
                        ? 'Last backup: ${DateFormat('MMM d, yyyy h:mm a').format(_backupInfo!.modifiedTime!)}'
                        : 'Backup your data to Google Drive',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_isBackingUp)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            else
              Icon(
                Icons.backup,
                color: isLight
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleDriveRestoreTile() {
    final isAmoled =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.amoled;
    final isLight =
        Provider.of<MoneyProvider>(context, listen: false).appThemeMode ==
        AppThemeMode.light;
    return GestureDetector(
      onTap: _isRestoring ? null : _restoreFromGoogleDrive,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAmoled ? Colors.transparent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAmoled ? Colors.white : Colors.green.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAmoled
                    ? Colors.transparent
                    : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isAmoled
                    ? Border.all(color: Colors.white.withOpacity(0.2))
                    : null,
              ),
              child: Icon(
                Icons.cloud_download,
                color: isLight
                    ? Colors.black
                    : (isAmoled ? Colors.white : Colors.green),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restore from Google Drive',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _backupInfo != null
                        ? 'Backup available'
                        : 'No backup found',
                    style: TextStyle(
                      color: _backupInfo != null
                          ? Colors.green.withOpacity(0.8)
                          : Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_isRestoring)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
            else
              Icon(
                Icons.restore,
                color: isLight
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}
