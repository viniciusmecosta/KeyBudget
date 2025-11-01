import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/ocr_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/view/ocr_detailed_viewer_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/expense_form.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _motivationController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;
  bool _isSaving = false;
  bool _isScanning = false;

  String? _processedImagePath;
  RecognizedText? _recognizedText;

  Map<OcrTargetField, String> _currentOcrAssignments = {};

  final _ocrService = OcrService();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() {
        _isScanning = true;
        _processedImagePath = null;
        _recognizedText = null;
        _currentOcrAssignments.clear();
      });

      final fileForOcr = XFile(pickedFile.path);
      final recognizedText = await _ocrService.processImage(fileForOcr);
      final extractedData = _ocrService.extractExpenseData(recognizedText.text);

      if (!mounted) return;

      final amount = extractedData['amount'] as double?;
      final date = extractedData['date'] as DateTime?;
      final description = extractedData['description'] as String?;

      _amountController.updateValue(0);
      _locationController.clear();
      _motivationController.clear();

      setState(() {
        _processedImagePath = pickedFile.path;
        _recognizedText = recognizedText;

        if (amount != null) {
          _amountController.updateValue(amount);
          _currentOcrAssignments[OcrTargetField.amount] =
              _findOriginalTextForAmount(recognizedText, amount) ??
                  amount.toStringAsFixed(2).replaceAll('.', ',');
        }
        if (date != null) {
          _selectedDate = date;
          _currentOcrAssignments[OcrTargetField.date] =
              _findOriginalTextForDate(recognizedText, date) ??
                  DateFormat('dd/MM/yyyy').format(date);
        }
        if (description != null) {
          _locationController.text = description;
          _currentOcrAssignments[OcrTargetField.location] = description;
        }
      });

      final foundParts = [
        if (amount != null) 'valor',
        if (date != null) 'data',
        if (description != null) 'descrição'
      ];
      if (foundParts.isNotEmpty) {
        SnackbarService.showInfo(
            context, '${foundParts.join(', ')} preenchido(s)! Verifique.');
      } else {
        SnackbarService.showInfo(
            context, 'Nenhum dado preenchido automaticamente.');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarService.showError(
          context, 'Falha ao processar a imagem. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  String? _findOriginalTextForAmount(RecognizedText rText, double amount) {
    String amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');
    String amountStrNoComma = amount.toStringAsFixed(0);
    for (var block in rText.blocks) {
      var cleanBlock =
          block.text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
      if (block.text.contains(amountStr) ||
          cleanBlock.contains(amount.toStringAsFixed(2)) ||
          block.text.contains(amountStrNoComma)) {
        return block.text;
      }
    }
    return null;
  }

  String? _findOriginalTextForDate(RecognizedText rText, DateTime date) {
    String dateStr = DateFormat('dd/MM/yyyy').format(date);
    String dateStrAlt = DateFormat('dd-MM-yyyy').format(date);
    for (var block in rText.blocks) {
      if (block.text.contains(dateStr) || block.text.contains(dateStrAlt)) {
        return block.text;
      }
    }
    return null;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _scanReceipt(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.of(context).pop();
                _scanReceipt(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailedViewer() async {
    if (_processedImagePath == null || _recognizedText == null) return;

    final initialAssignmentsForViewer = Map<OcrTargetField, String>.fromEntries(
        _currentOcrAssignments.entries
            .where((e) => e.value.isNotEmpty)
            .cast<MapEntry<OcrTargetField, String>>());

    final Map<OcrTargetField, String>? corrections =
        await Navigator.push<Map<OcrTargetField, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => OcrDetailedViewerScreen(
          imagePath: _processedImagePath!,
          recognizedText: _recognizedText!,
          initialAssignments: initialAssignmentsForViewer,
        ),
      ),
    );

    if (corrections != null && mounted) {
      _applyOcrCorrections(corrections, context);
      setState(() {
        _currentOcrAssignments = corrections;
      });
    }
  }

  void _applyOcrCorrections(
      Map<OcrTargetField, String> corrections, BuildContext currentContext) {
    setState(() {
      _amountController.updateValue(0);
      _selectedDate = DateTime.now();
      _motivationController.clear();
      _locationController.clear();

      corrections.forEach((field, text) {
        switch (field) {
          case OcrTargetField.amount:
            try {
              final cleanValue =
                  text.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
              final doubleValue = double.parse(cleanValue);
              _amountController.updateValue(doubleValue);
            } catch (e) {
              _amountController.updateValue(0);
            }
            break;
          case OcrTargetField.date:
            DateTime? parsedDate;
            try {
              parsedDate = DateFormat('dd/MM/yyyy').parseStrict(text);
            } catch (_) {}
            if (parsedDate == null) {
              try {
                parsedDate = DateFormat('dd-MM-yyyy').parseStrict(text);
              } catch (_) {}
            }
            if (parsedDate == null) {
              try {
                parsedDate = DateFormat('yyyy-MM-dd').parseStrict(text);
              } catch (_) {}
            }
            if (parsedDate != null) {
              _selectedDate = parsedDate;
            }
            break;
          case OcrTargetField.motivation:
            _motivationController.text = text;
            break;
          case OcrTargetField.location:
            _locationController.text = text;
            break;
          case OcrTargetField.none:
            break;
        }
      });
      SnackbarService.showSuccess(
          currentContext, 'Campos atualizados com as seleções!');
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amountController.numberValue == 0) {
      SnackbarService.showError(context, 'O valor não pode ser zero.');
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldContext = context;
    final userId = authViewModel.currentUser!.id;
    final newExpense = Expense(
      amount: _amountController.numberValue,
      date: _selectedDate,
      categoryId: _selectedCategory?.id,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
    );
    await expenseViewModel.addExpense(userId, newExpense);
    if (!scaffoldContext.mounted) return;
    setState(() => _isSaving = false);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
        actions: [
          IconButton(
            icon: Icon(Icons.document_scanner_outlined,
                color: _processedImagePath != null
                    ? theme.colorScheme.primary
                    : null),
            onPressed: _isScanning ? null : _showImageSourceDialog,
            tooltip: 'Escanear Recibo',
          ),
          if (_processedImagePath != null && _recognizedText != null)
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: _openDetailedViewer,
              tooltip: 'Corrigir Dados da Imagem',
            ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 4),
                    Text('Analisando imagem...')
                  ],
                ),
              ),
            Expanded(
              child: ExpenseForm(
                formKey: _formKey,
                amountController: _amountController,
                motivationController: _motivationController,
                locationController: _locationController,
                selectedDate: _selectedDate,
                selectedCategory: _selectedCategory,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                isEditing: true,
                imagePreviewWidget: _processedImagePath != null
                    ? GestureDetector(
                        onTap: _openDetailedViewer,
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(
                              top: AppTheme.spaceM, bottom: AppTheme.spaceS),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                            image: DecorationImage(
                              image: FileImage(File(_processedImagePath!)),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha((255 * 0.3).round()),
                                  BlendMode.darken),
                            ),
                          ),
                          child: Center(
                              child: Icon(Icons.touch_app_outlined,
                                  color: Colors.white
                                      .withAlpha((255 * 0.8).round()),
                                  size: 40)),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary, strokeWidth: 2.0))
                  : const Text('Salvar Despesa'),
            ),
          ],
        ),
      )),
    );
  }
}
