import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/app_theme.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? htmlUrl;
  final DateTime? publishedAt;
  final bool updateAvailable;
  final String? fileName;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.htmlUrl,
    this.publishedAt,
    required this.updateAvailable,
    this.fileName,
  });
}

class UpdateService {
  static const String _repoOwner = 'Bhanu7773-dev';
  static const String _repoName = 'PennyWise';
  static const String _apiUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Get the current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.4';
    }
  }

  /// Check for updates from GitHub releases
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final currentVersion = await getCurrentVersion();
      
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Get version from tag_name (remove 'v' prefix if present)
        String latestVersion = data['tag_name'] ?? '';
        if (latestVersion.startsWith('v')) {
          latestVersion = latestVersion.substring(1);
        }

        // Get APK download URL from assets
        String? downloadUrl;
        String? fileName;
        final assets = data['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = asset['name']?.toString() ?? '';
            if (name.toLowerCase().endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'];
              fileName = name;
              break;
            }
          }
        }

        final updateAvailable = _isNewerVersion(latestVersion, currentVersion);

        return UpdateInfo(
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          releaseNotes: data['body'],
          downloadUrl: downloadUrl,
          htmlUrl: data['html_url'],
          publishedAt: data['published_at'] != null 
              ? DateTime.tryParse(data['published_at']) 
              : null,
          updateAvailable: updateAvailable,
          fileName: fileName,
        );
      } else if (response.statusCode == 404) {
        // No releases found
        final currentVersion = await getCurrentVersion();
        return UpdateInfo(
          latestVersion: currentVersion,
          currentVersion: currentVersion,
          updateAvailable: false,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Compare version strings (returns true if latest > current)
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Ensure both lists have 3 parts
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      
      return false; // Versions are equal
    } catch (e) {
      return false;
    }
  }

  /// Request install packages permission (Android 8+)
  static Future<bool> _requestInstallPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  /// Get download directory
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use external storage for downloads
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        final downloadDir = Directory('${dir.path}/updates');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    }
    // Fallback to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/updates');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Show download progress dialog and download APK
  static Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {
    if (info.downloadUrl == null) {
      _showErrorSnackBar(context, 'No download URL available');
      return;
    }

    // Request install permission first
    final hasPermission = await _requestInstallPermission();
    if (!hasPermission) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Install permission denied. Please enable it in settings.');
      }
      return;
    }

    // Show download dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DownloadProgressDialog(
          downloadUrl: info.downloadUrl!,
          fileName: info.fileName ?? 'pennywise_${info.latestVersion}.apk',
          version: info.latestVersion,
        ),
      );
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.expense,
      ),
    );
  }

  /// Show update dialog
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.system_update, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'v${info.currentVersion}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Latest',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'v${info.latestVersion}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'What\'s New:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              downloadAndInstall(context, info);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download & Install'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show "no update" or "up to date" dialog
  static Future<void> showUpToDateDialog(BuildContext context, String currentVersion) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.income.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppTheme.income),
            ),
            const SizedBox(width: 12),
            const Text(
              'Up to Date',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'You\'re running the latest version (v$currentVersion)',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.expense.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: AppTheme.expense),
            ),
            const SizedBox(width: 12),
            const Text(
              'Check Failed',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Unable to check for updates. Please check your internet connection and try again.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Download Progress Dialog Widget
class _DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final String fileName;
  final String version;

  const _DownloadProgressDialog({
    required this.downloadUrl,
    required this.fileName,
    required this.version,
  });

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  String _status = 'Preparing download...';
  bool _isDownloading = true;
  bool _hasError = false;
  String? _errorMessage;
  CancelToken? _cancelToken;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    _cancelToken = CancelToken();
    
    try {
      setState(() {
        _status = 'Starting download...';
        _progress = 0;
      });

      // Get download directory
      final dir = await UpdateService._getDownloadDirectory();
      _filePath = '${dir.path}/${widget.fileName}';

      // Delete old file if exists
      final oldFile = File(_filePath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      setState(() {
        _status = 'Downloading v${widget.version}...';
      });

      // Download using Dio
      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        _filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              final mb = (received / 1024 / 1024).toStringAsFixed(1);
              final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
              _status = 'Downloading... $mb MB / $totalMb MB';
            });
          }
        },
      );

      setState(() {
        _status = 'Download complete! Installing...';
        _progress = 1.0;
        _isDownloading = false;
      });

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      // Install APK
      await _installApk();

    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // User cancelled
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() {
        _hasError = true;
        _isDownloading = false;
        _errorMessage = 'Download failed: ${e.message}';
        _status = 'Download failed';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isDownloading = false;
        _errorMessage = 'Error: $e';
        _status = 'Download failed';
      });
    }
  }

  Future<void> _installApk() async {
    if (_filePath == null) return;

    try {
      final result = await OpenFilex.open(_filePath!);
      
      if (result.type != ResultType.done) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not open installer: ${result.message}';
        });
      } else {
        // Close dialog after successful install trigger
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Install failed: $e';
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hasError 
                  ? AppTheme.expense.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _hasError ? Icons.error_outline : Icons.download,
              color: _hasError ? AppTheme.expense : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hasError ? 'Download Failed' : 'Downloading Update',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasError) ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _isDownloading ? _progress : 1.0,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress >= 1.0 ? AppTheme.income : AppTheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress percentage
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Status text
          Text(
            _status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_hasError && _errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppTheme.expense,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_isDownloading)
          TextButton(
            onPressed: _cancelDownload,
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          )
        else if (_hasError) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
                _isDownloading = true;
              });
              _startDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
