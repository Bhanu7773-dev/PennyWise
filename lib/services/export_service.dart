import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';

class ImportResult {
  final List<Transaction> transactions;
  final List<String> errors;
  final int totalRows;
  final int successfulRows;

  ImportResult({
    required this.transactions,
    required this.errors,
    required this.totalRows,
    required this.successfulRows,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => transactions.isEmpty;
}

class ExportService {
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), try MANAGE_EXTERNAL_STORAGE for full file access
      var manageStatus = await Permission.manageExternalStorage.status;

      if (!manageStatus.isGranted) {
        // Request MANAGE_EXTERNAL_STORAGE permission
        final result = await Permission.manageExternalStorage.request();

        if (result.isGranted) {
          return true;
        }

        // If denied, check if permanently denied and open settings
        if (result.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        // If not granted and not permanently denied, try regular storage permission as fallback
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          final storageResult = await Permission.storage.request();

          if (!storageResult.isGranted) {
            if (storageResult.isPermanentlyDenied) {
              await openAppSettings();
            }
            return false;
          }
          return storageResult.isGranted;
        }
        return storageStatus.isGranted;
      }

      return true; // MANAGE_EXTERNAL_STORAGE already granted
    }
    return true; // iOS doesn't need explicit storage permission
  }

  Future<Directory?> _getPennyWiseDirectory() async {
    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        // Try to get external storage directory (internal storage on device)
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navigate to the root of internal storage
          final String externalPath = externalDirs.first.path;
          // Extract path up to Android/data/...
          final parts = externalPath.split('/');
          final androidIndex = parts.indexOf('Android');
          if (androidIndex > 0) {
            final basePath = parts.sublist(0, androidIndex).join('/');
            baseDir = Directory('$basePath/PennyWise');
          }
        }

        // Fallback to app-specific directory
        if (baseDir == null) {
          final appDir = await getApplicationDocumentsDirectory();
          baseDir = Directory('${appDir.path}/PennyWise');
        }
      } else {
        // iOS: Use documents directory
        final appDir = await getApplicationDocumentsDirectory();
        baseDir = Directory('${appDir.path}/PennyWise');
      }

      // Create directory if it doesn't exist
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      return baseDir;
    } catch (e) {
      debugPrint('Error creating PennyWise directory: $e');
      return null;
    }
  }

  Future<String?> exportToCSV(List<Transaction> transactions) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final List<List<dynamic>> rows = [
        ['Date', 'Title', 'Category', 'Amount', 'Type'],
      ];

      for (var t in transactions) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(t.date),
          t.title,
          t.category,
          t.amount.toStringAsFixed(2),
          t.isExpense ? 'Expense' : 'Income',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      // Get PennyWise directory
      final directory = await _getPennyWiseDirectory();
      if (directory == null) {
        return null;
      }

      final fileName =
          'pennywise_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      debugPrint('CSV export error: $e');
      return null;
    }
  }

  Future<String?> exportToPDF(List<Transaction> transactions, {String currencySymbol = '₹'}) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final pdf = pw.Document();
      
      // Load font that supports currency symbols
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);
      
      final currencyFormat = NumberFormat.currency(
        symbol: currencySymbol,
        decimalDigits: 2,
      );

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttf,
          ),
          build: (pw.Context context) {
            return [
              pw.Text(
                'PennyWise Transaction Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: ttf),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
                cellStyle: pw.TextStyle(font: ttf),
                headers: ['Date', 'Title', 'Category', 'Amount', 'Type'],
                data: transactions
                    .map(
                      (t) => [
                        DateFormat('yyyy-MM-dd').format(t.date),
                        t.title,
                        t.category,
                        currencyFormat.format(t.amount),
                        t.isExpense ? 'Expense' : 'Income',
                      ],
                    )
                    .toList(),
              ),
            ];
          },
        ),
      );

      // Get PennyWise directory
      final directory = await _getPennyWiseDirectory();
      if (directory == null) {
        return null;
      }

      final fileName =
          'pennywise_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('PDF export error: $e');
      return null;
    }
  }

  // ==================== IMPORT METHODS ====================

  /// Pick a file for import
  Future<PlatformFile?> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('File picker error: $e');
      return null;
    }
  }

  /// Import transactions from a CSV file
  Future<ImportResult> importFromCSV(String filePath, {String? userId}) async {
    final List<Transaction> transactions = [];
    final List<String> errors = [];
    int totalRows = 0;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          transactions: [],
          errors: ['File not found: $filePath'],
          totalRows: 0,
          successfulRows: 0,
        );
      }

      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return ImportResult(
          transactions: [],
          errors: ['CSV file is empty'],
          totalRows: 0,
          successfulRows: 0,
        );
      }

      // Get headers (first row)
      final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      totalRows = rows.length - 1; // Exclude header row

      // Try to detect column mappings
      final columnMap = _detectCSVColumns(headers);

      if (columnMap['date'] == null || columnMap['amount'] == null) {
        return ImportResult(
          transactions: [],
          errors: ['CSV must contain at least Date and Amount columns'],
          totalRows: totalRows,
          successfulRows: 0,
        );
      }

      // Process data rows
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final transaction = _parseCSVRow(row, columnMap, userId);
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          errors.add('Row ${i + 1}: $e');
        }
      }

      return ImportResult(
        transactions: transactions,
        errors: errors,
        totalRows: totalRows,
        successfulRows: transactions.length,
      );
    } catch (e) {
      debugPrint('CSV import error: $e');
      return ImportResult(
        transactions: [],
        errors: ['Failed to read CSV file: $e'],
        totalRows: totalRows,
        successfulRows: 0,
      );
    }
  }

  /// Import transactions from a JSON file
  Future<ImportResult> importFromJSON(String filePath, {String? userId}) async {
    final List<Transaction> transactions = [];
    final List<String> errors = [];
    int totalRows = 0;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          transactions: [],
          errors: ['File not found: $filePath'],
          totalRows: 0,
          successfulRows: 0,
        );
      }

      final content = await file.readAsString();
      final dynamic jsonData = json.decode(content);

      List<dynamic> dataList;
      if (jsonData is List) {
        dataList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('transactions')) {
        dataList = jsonData['transactions'] as List;
      } else if (jsonData is Map) {
        // Single transaction
        dataList = [jsonData];
      } else {
        return ImportResult(
          transactions: [],
          errors: ['Invalid JSON format'],
          totalRows: 0,
          successfulRows: 0,
        );
      }

      totalRows = dataList.length;

      for (int i = 0; i < dataList.length; i++) {
        try {
          final item = dataList[i] as Map<String, dynamic>;
          final transaction = _parseJSONTransaction(item, userId);
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          errors.add('Item ${i + 1}: $e');
        }
      }

      return ImportResult(
        transactions: transactions,
        errors: errors,
        totalRows: totalRows,
        successfulRows: transactions.length,
      );
    } catch (e) {
      debugPrint('JSON import error: $e');
      return ImportResult(
        transactions: [],
        errors: ['Failed to read JSON file: $e'],
        totalRows: totalRows,
        successfulRows: 0,
      );
    }
  }

  /// Detect CSV column mappings from headers
  Map<String, int?> _detectCSVColumns(List<String> headers) {
    final Map<String, int?> columnMap = {
      'date': null,
      'title': null,
      'category': null,
      'amount': null,
      'type': null,
      'notes': null,
    };

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();

      // Date column
      if (header.contains('date') || header.contains('time') || header == 'when') {
        columnMap['date'] = i;
      }
      // Title/Description column
      else if (header.contains('title') || 
               header.contains('description') || 
               header.contains('name') ||
               header.contains('memo') ||
               header.contains('payee') ||
               header.contains('merchant')) {
        columnMap['title'] = i;
      }
      // Category column
      else if (header.contains('category') || header.contains('type') && !header.contains('trans')) {
        columnMap['category'] = i;
      }
      // Amount column
      else if (header.contains('amount') || 
               header.contains('value') || 
               header.contains('sum') ||
               header.contains('price') ||
               header.contains('debit') ||
               header.contains('credit')) {
        columnMap['amount'] = i;
      }
      // Transaction type column (expense/income)
      else if (header.contains('trans') && header.contains('type') ||
               header == 'type' ||
               header.contains('expense') ||
               header.contains('income') ||
               header.contains('direction')) {
        columnMap['type'] = i;
      }
      // Notes column
      else if (header.contains('note') || header.contains('remark') || header.contains('comment')) {
        columnMap['notes'] = i;
      }
    }

    return columnMap;
  }

  /// Parse a CSV row into a Transaction
  Transaction? _parseCSVRow(List<dynamic> row, Map<String, int?> columnMap, String? userId) {
    try {
      // Parse date
      final dateIndex = columnMap['date']!;
      DateTime? date;
      final dateValue = row[dateIndex].toString().trim();
      
      // Try multiple date formats
      date = _parseDate(dateValue);
      if (date == null) {
        throw FormatException('Invalid date format: $dateValue');
      }

      // Parse amount
      final amountIndex = columnMap['amount']!;
      double amount = _parseAmount(row[amountIndex].toString());

      // Parse title
      String title = 'Imported Transaction';
      if (columnMap['title'] != null && columnMap['title']! < row.length) {
        title = row[columnMap['title']!].toString().trim();
        if (title.isEmpty) title = 'Imported Transaction';
      }

      // Parse category
      String category = 'Other';
      if (columnMap['category'] != null && columnMap['category']! < row.length) {
        category = row[columnMap['category']!].toString().trim();
        if (category.isEmpty) category = 'Other';
      }

      // Parse type (expense/income)
      bool isExpense = amount < 0;
      if (columnMap['type'] != null && columnMap['type']! < row.length) {
        final typeValue = row[columnMap['type']!].toString().toLowerCase().trim();
        if (typeValue.contains('expense') || typeValue.contains('debit') || typeValue == '-') {
          isExpense = true;
        } else if (typeValue.contains('income') || typeValue.contains('credit') || typeValue == '+') {
          isExpense = false;
        }
      }

      // Parse notes
      String? notes;
      if (columnMap['notes'] != null && columnMap['notes']! < row.length) {
        notes = row[columnMap['notes']!].toString().trim();
        if (notes.isEmpty) notes = null;
      }

      // Make amount positive
      amount = amount.abs();

      return Transaction(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        date: date,
        isExpense: isExpense,
        category: category,
        userId: userId,
        notes: notes,
      );
    } catch (e) {
      debugPrint('Error parsing CSV row: $e');
      rethrow;
    }
  }

  /// Parse a JSON object into a Transaction
  Transaction? _parseJSONTransaction(Map<String, dynamic> json, String? userId) {
    try {
      // Get date
      DateTime date;
      if (json.containsKey('date')) {
        final dateValue = json['date'];
        if (dateValue is String) {
          date = DateTime.parse(dateValue);
        } else if (dateValue is int) {
          date = DateTime.fromMillisecondsSinceEpoch(dateValue);
        } else {
          throw FormatException('Invalid date value');
        }
      } else {
        date = DateTime.now();
      }

      // Get amount
      double amount;
      if (json.containsKey('amount')) {
        amount = (json['amount'] is int) 
            ? (json['amount'] as int).toDouble() 
            : (json['amount'] as double);
      } else {
        throw FormatException('Amount is required');
      }

      // Get title
      String title = json['title']?.toString() ?? 
                     json['description']?.toString() ?? 
                     json['name']?.toString() ?? 
                     'Imported Transaction';

      // Get category
      String category = json['category']?.toString() ?? 'Other';

      // Get type
      bool isExpense = true;
      if (json.containsKey('isExpense')) {
        isExpense = json['isExpense'] == true;
      } else if (json.containsKey('type')) {
        final type = json['type'].toString().toLowerCase();
        isExpense = type.contains('expense') || type == 'debit';
      } else {
        isExpense = amount < 0;
      }

      // Get notes
      String? notes = json['notes']?.toString();

      amount = amount.abs();

      return Transaction(
        id: json['id']?.toString() ?? const Uuid().v4(),
        title: title,
        amount: amount,
        date: date,
        isExpense: isExpense,
        category: category,
        userId: userId ?? json['userId']?.toString(),
        notes: notes,
      );
    } catch (e) {
      debugPrint('Error parsing JSON transaction: $e');
      rethrow;
    }
  }

  /// Try to parse date from various formats
  DateTime? _parseDate(String value) {
    final formats = [
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'yyyy/MM/dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy.MM.dd',
      'dd.MM.yyyy',
      'MMM dd, yyyy',
      'dd MMM yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
    ];

    // Try ISO format first
    try {
      return DateTime.parse(value);
    } catch (_) {}

    // Try other formats
    for (final format in formats) {
      try {
        return DateFormat(format).parse(value);
      } catch (_) {}
    }

    return null;
  }

  /// Parse amount from string (handles currency symbols, commas, etc.)
  double _parseAmount(String value) {
    // Remove currency symbols, spaces, and normalize
    String cleaned = value
        .replaceAll(RegExp(r'[^\d.,\-+]'), '')
        .trim();

    // Handle comma as decimal separator (European format)
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
    } else {
      // Remove thousand separators
      cleaned = cleaned.replaceAll(',', '');
    }

    if (cleaned.isEmpty) return 0.0;

    return double.parse(cleaned);
  }

  /// Export transactions to JSON format
  Future<String?> exportToJSON(List<Transaction> transactions) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final List<Map<String, dynamic>> jsonList = 
          transactions.map((t) => t.toJson()).toList();
      
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toIso8601String(),
        'count': transactions.length,
        'transactions': jsonList,
      });

      // Get PennyWise directory
      final directory = await _getPennyWiseDirectory();
      if (directory == null) {
        return null;
      }

      final fileName =
          'pennywise_transactions_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('JSON export error: $e');
      return null;
    }
  }
}
