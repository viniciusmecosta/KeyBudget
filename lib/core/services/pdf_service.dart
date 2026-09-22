import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/widget_to_image.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/domain/analysis_snapshot.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/analysis/widgets/category_analysis_section_widget.dart';
import 'package:key_budget/features/analysis/widgets/monthly_trend_section_widget.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<void> exportExpensesPdf(
    BuildContext context,
    List<Expense> expenses,
    AnalysisViewModel analysisViewModel,
    CategoryViewModel categoryViewModel,
  ) async {
    try {
      final PdfDocument document = PdfDocument();
      PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      double currentY = 0;

      final ByteData logoData = await rootBundle.load('assets/icon/logov2.png');
      final PdfBitmap logo = PdfBitmap(logoData.buffer.asUint8List());

      final ByteData fontData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final PdfFont font = PdfTrueTypeFont(fontData.buffer.asUint8List(), 10);
      final PdfFont headerFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        12,
        style: PdfFontStyle.bold,
      );
      final PdfFont titleFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        18,
        style: PdfFontStyle.bold,
      );

      final PdfColor primaryColor = PdfColor(
        (AppTheme.primary.r * 255.0).round() & 0xff,
        (AppTheme.primary.g * 255.0).round() & 0xff,
        (AppTheme.primary.b * 255.0).round() & 0xff,
      );
      final PdfColor onSurfaceColor = PdfColor(
        (AppTheme.onSurface.r * 255.0).round() & 0xff,
        (AppTheme.onSurface.g * 255.0).round() & 0xff,
        (AppTheme.onSurface.b * 255.0).round() & 0xff,
      );
      final PdfColor surfaceColor = PdfColor(
        (AppTheme.surface.r * 255.0).round() & 0xff,
        (AppTheme.surface.g * 255.0).round() & 0xff,
        (AppTheme.surface.b * 255.0).round() & 0xff,
      );
      final PdfColor lightGreyColor = PdfColor(
        (AppTheme.surfaceContainerHighest.r * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.g * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.b * 255.0).round() & 0xff,
      );

      page.graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 40, 40));
      page.graphics.drawString(
        'Relatório de Despesas',
        titleFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(50, 5, pageSize.width - 50, 30),
      );
      page.graphics.drawString(
        'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        font,
        brush: PdfSolidBrush(onSurfaceColor),
        bounds: Rect.fromLTWH(50, 30, pageSize.width - 50, 20),
      );
      currentY += 60;

      if (expenses.isNotEmpty) {
        page.graphics.drawString(
          'Tabela de Despesas',
          headerFont,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20),
        );
        currentY += 25;

        final PdfGrid grid = PdfGrid();
        grid.columns.add(count: 6);
        grid.headers.add(1);
        final PdfGridRow header = grid.headers[0];
        header.cells[0].value = 'Data';
        header.cells[1].value = 'Tipo';
        header.cells[2].value = 'Valor (R\$)';
        header.cells[3].value = 'Categoria';
        header.cells[4].value = 'Motivação';
        header.cells[5].value = 'Local';

        for (int i = 0; i < header.cells.count; i++) {
          header.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(primaryColor),
            textBrush: PdfSolidBrush(surfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
              alignment: PdfTextAlignment.center,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }

        double totalExpensesAmount = 0;
        double totalIncomesAmount = 0;
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: '',
        );

        for (var expense in expenses) {
          final isIncome = expense.isIncome ?? false;
          final PdfGridRow row = grid.rows.add();
          row.cells[0].value = DateFormat('dd/MM/yyyy').format(expense.date);
          row.cells[1].value = isIncome ? 'Receita' : 'Despesa';
          row.cells[2].value = currencyFormat.format(expense.amount);

          final category = categoryViewModel.getCategoryById(
            expense.categoryId,
          );
          final categoryName = category?.name ??
              (expense.categoryId == null || expense.categoryId!.isEmpty
                  ? 'Sem categoria'
                  : 'Categoria removida');
          row.cells[3].value = categoryName;
          row.cells[4].value = expense.motivation ?? '';
          row.cells[5].value = expense.location ?? '';

          if (isIncome) {
            totalIncomesAmount += expense.amount;
          } else {
            totalExpensesAmount += expense.amount;
          }

          for (int i = 0; i < row.cells.count; i++) {
            row.cells[i].style = PdfGridCellStyle(
              font: font,
              textBrush: PdfSolidBrush(onSurfaceColor),
              backgroundBrush: PdfSolidBrush(
                expenses.indexOf(expense) % 2 == 0
                    ? surfaceColor
                    : lightGreyColor,
              ),
              cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
              format: PdfStringFormat(
                alignment: i == 2
                    ? PdfTextAlignment.right
                    : (i == 0 || i == 1 ? PdfTextAlignment.center : PdfTextAlignment.left),
                lineAlignment: PdfVerticalAlignment.middle,
              ),
            );
          }
        }

        final PdfGridRow expenseTotalRow = grid.rows.add();
        expenseTotalRow.cells[0].value = 'Total Despesas';
        expenseTotalRow.cells[1].value = '';
        expenseTotalRow.cells[2].value = currencyFormat.format(totalExpensesAmount);
        for (int i = 3; i < expenseTotalRow.cells.count; i++) {
          expenseTotalRow.cells[i].value = '';
        }
        for (int i = 0; i < expenseTotalRow.cells.count; i++) {
          expenseTotalRow.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(lightGreyColor),
            textBrush: PdfSolidBrush(onSurfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
              alignment: i == 2
                  ? PdfTextAlignment.right
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }

        final PdfGridRow incomeTotalRow = grid.rows.add();
        incomeTotalRow.cells[0].value = 'Total Receitas';
        incomeTotalRow.cells[1].value = '';
        incomeTotalRow.cells[2].value = currencyFormat.format(totalIncomesAmount);
        for (int i = 3; i < incomeTotalRow.cells.count; i++) {
          incomeTotalRow.cells[i].value = '';
        }
        for (int i = 0; i < incomeTotalRow.cells.count; i++) {
          incomeTotalRow.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(lightGreyColor),
            textBrush: PdfSolidBrush(onSurfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
              alignment: i == 2
                  ? PdfTextAlignment.right
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }

        final PdfGridRow balanceRow = grid.rows.add();
        balanceRow.cells[0].value = 'Saldo Líquido';
        balanceRow.cells[1].value = '';
        balanceRow.cells[2].value = currencyFormat.format(totalIncomesAmount - totalExpensesAmount);
        for (int i = 3; i < balanceRow.cells.count; i++) {
          balanceRow.cells[i].value = '';
        }
        for (int i = 0; i < balanceRow.cells.count; i++) {
          balanceRow.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(primaryColor),
            textBrush: PdfSolidBrush(surfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
              alignment: i == 2
                  ? PdfTextAlignment.right
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }

        final PdfLayoutResult? gridResult = grid.draw(
          page: page,
          bounds: Rect.fromLTWH(
            0,
            currentY,
            pageSize.width,
            pageSize.height - currentY,
          ),
        );

        if (gridResult != null) {
          currentY = gridResult.bounds.bottom + 20;
          page = gridResult.page;
        } else {
          currentY += 200;
        }
      } else {
        page.graphics.drawString(
          'Nenhuma despesa no período selecionado.',
          font,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20),
        );
        currentY += 30;
      }

      final monthlyTrendKey = GlobalKey();
      final categoryAnalysisKey = GlobalKey();

      final monthlyTrendChart = Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(24),
            child: const MonthlyTrendSectionWidget(),
          ),
        ),
      );

      final categoryAnalysisChart = Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(24),
            child: const CategoryAnalysisSectionWidget(),
          ),
        ),
      );

      if (!context.mounted) return;

      final monthlyTrendImageBytes =
          await WidgetToImage.captureWidgetFromProvider(
            context,
            ProviderScope(
              child: Builder(
                key: monthlyTrendKey,
                builder: (ctx) =>
                    Theme(data: AppTheme.lightTheme, child: monthlyTrendChart),
              ),
            ),
            wait: const Duration(milliseconds: 1500),
          );

      if (!context.mounted) return;

      final categoryAnalysisImageBytes =
          await WidgetToImage.captureWidgetFromProvider(
            context,
            ProviderScope(
              child: Builder(
                key: categoryAnalysisKey,
                builder: (ctx) => Theme(
                  data: AppTheme.lightTheme,
                  child: categoryAnalysisChart,
                ),
              ),
            ),
            wait: const Duration(milliseconds: 1500),
          );

      if (monthlyTrendImageBytes != null) {
        page = document.pages.add();
        currentY = 0;

        page.graphics.drawString(
          'Gráficos de Análise - Evolução Mensal',
          headerFont,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20),
        );
        currentY += 30;

        final PdfBitmap monthlyTrendImage = PdfBitmap(monthlyTrendImageBytes);
        final imageSize = Size(
          monthlyTrendImage.width.toDouble(),
          monthlyTrendImage.height.toDouble(),
        );
        final drawSize = _calculatePdfImageSize(
          imageSize,
          Size(pageSize.width * 0.9, pageSize.height - currentY - 20),
        );

        page.graphics.drawImage(
          monthlyTrendImage,
          Rect.fromLTWH(
            (pageSize.width - drawSize.width) / 2,
            currentY,
            drawSize.width,
            drawSize.height,
          ),
        );
      }

      if (categoryAnalysisImageBytes != null) {
        page = document.pages.add();
        currentY = 0;

        page.graphics.drawString(
          'Gráficos de Análise - Por Categoria',
          headerFont,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20),
        );
        currentY += 30;

        final PdfBitmap categoryAnalysisImage = PdfBitmap(
          categoryAnalysisImageBytes,
        );
        final imageSize = Size(
          categoryAnalysisImage.width.toDouble(),
          categoryAnalysisImage.height.toDouble(),
        );
        final drawSize = _calculatePdfImageSize(
          imageSize,
          Size(pageSize.width * 0.9, pageSize.height - currentY - 20),
        );

        page.graphics.drawImage(
          categoryAnalysisImage,
          Rect.fromLTWH(
            (pageSize.width - drawSize.width) / 2,
            currentY,
            drawSize.width,
            drawSize.height,
          ),
        );
      }

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_expenses_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      if (!context.mounted) return;

      final params = ShareParams(
        files: [XFile(filePath)],
        text: 'Relatório de Despesas e Análise',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (!context.mounted) return;
      SnackbarService.showError(
        context,
        'Falha ao gerar relatório de despesas: $e',
        title: 'Erro Exportação PDF',
      );
    }
  }

  Future<void> exportCredentialsPdf(
    BuildContext context,
    CredentialViewModel credentialViewModel,
  ) async {
    try {
      final credentials = credentialViewModel.allCredentials;
      final PdfDocument document = PdfDocument();
      PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      double currentY = 0;

      final ByteData logoData = await rootBundle.load('assets/icon/logov2.png');
      final PdfBitmap logo = PdfBitmap(logoData.buffer.asUint8List());

      final ByteData fontData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final PdfFont font = PdfTrueTypeFont(fontData.buffer.asUint8List(), 8);
      final PdfFont headerFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        9,
        style: PdfFontStyle.bold,
      );
      final PdfFont titleFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        18,
        style: PdfFontStyle.bold,
      );

      final PdfColor primaryColor = PdfColor(
        (AppTheme.primary.r * 255.0).round() & 0xff,
        (AppTheme.primary.g * 255.0).round() & 0xff,
        (AppTheme.primary.b * 255.0).round() & 0xff,
      );
      final PdfColor onSurfaceColor = PdfColor(
        (AppTheme.onSurface.r * 255.0).round() & 0xff,
        (AppTheme.onSurface.g * 255.0).round() & 0xff,
        (AppTheme.onSurface.b * 255.0).round() & 0xff,
      );
      final PdfColor surfaceColor = PdfColor(
        (AppTheme.surface.r * 255.0).round() & 0xff,
        (AppTheme.surface.g * 255.0).round() & 0xff,
        (AppTheme.surface.b * 255.0).round() & 0xff,
      );
      final PdfColor lightGreyColor = PdfColor(
        (AppTheme.surfaceContainerHighest.r * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.g * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.b * 255.0).round() & 0xff,
      );

      page.graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 40, 40));
      page.graphics.drawString(
        'Relatório de Credenciais',
        titleFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(50, 5, pageSize.width - 50, 30),
      );
      page.graphics.drawString(
        'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        font,
        brush: PdfSolidBrush(onSurfaceColor),
        bounds: Rect.fromLTWH(50, 30, pageSize.width - 50, 20),
      );
      currentY = 60;

      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 6);
      grid.headers.add(1);
      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'Local/Serviço';
      header.cells[1].value = 'Login';
      header.cells[2].value = 'Senha';
      header.cells[3].value = 'Email';
      header.cells[4].value = 'Telefone';
      header.cells[5].value = 'Notas';

      for (int i = 0; i < header.cells.count; i++) {
        header.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(primaryColor),
          textBrush: PdfSolidBrush(surfaceColor),
          font: headerFont,
          cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4),
        );
        grid.columns[i].width = [70, 65, 60, 85, 60, 85][i].toDouble();
      }

      for (var credential in credentials) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = credential.location;
        row.cells[1].value = credential.login;
        row.cells[2].value = credentialViewModel.decryptPassword(
          credential.encryptedPassword,
        );
        row.cells[3].value = credential.email ?? '';
        row.cells[4].value = credential.phoneNumber ?? '';
        row.cells[5].value = credential.notes ?? '';

        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: font,
            textBrush: PdfSolidBrush(onSurfaceColor),
            backgroundBrush: PdfSolidBrush(
              credentials.indexOf(credential) % 2 == 0
                  ? surfaceColor
                  : lightGreyColor,
            ),
            cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4),
            format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
          );
          row.cells[i].stringFormat = PdfStringFormat(
            wordWrap: PdfWordWrapType.word,
          );
        }
      }

      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4),
      );

      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(
          0,
          currentY,
          pageSize.width,
          pageSize.height - currentY,
        ),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_credentials_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      if (!context.mounted) return;

      final params = ShareParams(
        files: [XFile(filePath)],
        text: 'Relatório de Credenciais',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (!context.mounted) return;
      SnackbarService.showError(
        context,
        'Falha ao gerar relatório de credenciais: $e',
        title: 'Erro Exportação PDF',
      );
    }
  }

  Future<void> exportAnalysisPdf(
    BuildContext context,
    AnalysisViewModel analysisViewModel, {
    AnalysisSnapshot? snapshot,
  }) async {
    try {

      final snap = snapshot ?? analysisViewModel.currentSnapshot;
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat =
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
      final startDateStr = dateFormat.format(snap.query.range.startInclusive);
      final endDateStr = dateFormat.format(
        snap.query.range.endExclusive.subtract(const Duration(milliseconds: 1)),
      );

      final PdfDocument document = PdfDocument();

      final ByteData logoData = await rootBundle.load('assets/icon/logov2.png');
      final PdfBitmap logo = PdfBitmap(logoData.buffer.asUint8List());
      final ByteData fontData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final PdfFont font = PdfTrueTypeFont(fontData.buffer.asUint8List(), 10);
      final PdfFont boldFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        10,
        style: PdfFontStyle.bold,
      );
      final PdfFont headerFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        14,
        style: PdfFontStyle.bold,
      );
      final PdfFont titleFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        20,
        style: PdfFontStyle.bold,
      );

      final PdfColor primaryColor = PdfColor(
        (AppTheme.primary.r * 255.0).round() & 0xff,
        (AppTheme.primary.g * 255.0).round() & 0xff,
        (AppTheme.primary.b * 255.0).round() & 0xff,
      );
      final PdfColor onSurfaceColor = PdfColor(
        (AppTheme.onSurface.r * 255.0).round() & 0xff,
        (AppTheme.onSurface.g * 255.0).round() & 0xff,
        (AppTheme.onSurface.b * 255.0).round() & 0xff,
      );
      final PdfColor surfaceColor = PdfColor(
        (AppTheme.surface.r * 255.0).round() & 0xff,
        (AppTheme.surface.g * 255.0).round() & 0xff,
        (AppTheme.surface.b * 255.0).round() & 0xff,
      );
      final PdfColor lightGreyColor = PdfColor(
        (AppTheme.surfaceContainerHighest.r * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.g * 255.0).round() & 0xff,
        (AppTheme.surfaceContainerHighest.b * 255.0).round() & 0xff,
      );

      PdfPage page1 = document.pages.add();
      final Size pageSize = page1.getClientSize();
      double currentY = 0;

      page1.graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 45, 45));
      page1.graphics.drawString(
        'Relatório de Análise Financeira',
        titleFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(55, 5, pageSize.width - 55, 26),
      );
      page1.graphics.drawString(
        'Período: $startDateStr até $endDateStr  |  Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(snap.capturedAt)}',
        font,
        brush: PdfSolidBrush(onSurfaceColor),
        bounds: Rect.fromLTWH(55, 32, pageSize.width - 55, 18),
      );
      currentY += 60;

      page1.graphics.drawString(
        'Resumo Consolidado',
        headerFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 22),
      );
      currentY += 25;

      final PdfGrid summaryGrid = PdfGrid();
      summaryGrid.columns.add(count: 4);
      final PdfGridRow summaryHeader = summaryGrid.headers.add(1)[0];
      summaryHeader.cells[0].value = 'Total Receitas';
      summaryHeader.cells[1].value = 'Total Despesas';
      summaryHeader.cells[2].value = 'Saldo Líquido';
      summaryHeader.cells[3].value = 'Média Mensal';

      for (int i = 0; i < 4; i++) {
        summaryHeader.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(primaryColor),
          textBrush: PdfSolidBrush(surfaceColor),
          font: boldFont,
          cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
          format: PdfStringFormat(
            alignment: PdfTextAlignment.center,
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      final PdfGridRow summaryRow = summaryGrid.rows.add();
      summaryRow.cells[0].value = currencyFormat.format(snap.totalIncomes.amountMinor / 100.0);
      summaryRow.cells[1].value = currencyFormat.format(snap.totalExpenses.amountMinor / 100.0);
      summaryRow.cells[2].value = currencyFormat.format(snap.balance.amountMinor / 100.0);
      summaryRow.cells[3].value = currencyFormat.format(snap.averageMonthlyExpense.amountMinor / 100.0);

      for (int i = 0; i < 4; i++) {
        summaryRow.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(lightGreyColor),
          textBrush: PdfSolidBrush(onSurfaceColor),
          font: boldFont,
          cellPadding: PdfPaddings(left: 4, right: 4, top: 6, bottom: 6),
          format: PdfStringFormat(
            alignment: PdfTextAlignment.center,
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      final summaryResult = summaryGrid.draw(
        page: page1,
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 50),
      );
      currentY = (summaryResult?.bounds.bottom ?? currentY + 50) + 20;

      page1.graphics.drawString(
        'Composição de Despesas por Categoria',
        headerFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 22),
      );
      currentY += 25;

      final PdfGrid categoryGrid = PdfGrid();
      categoryGrid.repeatHeader = true;
      categoryGrid.columns.add(count: 4);
      final PdfGridRow catHeader = categoryGrid.headers.add(1)[0];
      catHeader.cells[0].value = 'Categoria';
      catHeader.cells[1].value = 'Quantidade de Itens';
      catHeader.cells[2].value = 'Total Gasto';
      catHeader.cells[3].value = 'Participação (%)';

      for (int i = 0; i < 4; i++) {
        catHeader.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(primaryColor),
          textBrush: PdfSolidBrush(surfaceColor),
          font: boldFont,
          cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
          format: PdfStringFormat(
            alignment: i >= 2 ? PdfTextAlignment.right : (i == 1 ? PdfTextAlignment.center : PdfTextAlignment.left),
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      for (final group in snap.categoryDistribution) {
        final row = categoryGrid.rows.add();
        row.cells[0].value = group.categoryName;
        row.cells[1].value = group.itemsCount.toString();
        row.cells[2].value = currencyFormat.format(group.totalAmount.amountMinor / 100.0);
        row.cells[3].value = '${group.percentage.toStringAsFixed(1)}%';

        for (int i = 0; i < 4; i++) {
          row.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(
              snap.categoryDistribution.indexOf(group) % 2 == 0 ? surfaceColor : lightGreyColor,
            ),
            textBrush: PdfSolidBrush(onSurfaceColor),
            font: font,
            cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
            format: PdfStringFormat(
              alignment: i >= 2 ? PdfTextAlignment.right : (i == 1 ? PdfTextAlignment.center : PdfTextAlignment.left),
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }
      }

      final catTotalRow = categoryGrid.rows.add();
      catTotalRow.cells[0].value = 'Total';
      catTotalRow.cells[1].value = snap.expenseCount.toString();
      catTotalRow.cells[2].value = currencyFormat.format(snap.totalExpenses.amountMinor / 100.0);
      catTotalRow.cells[3].value = '100.0%';
      for (int i = 0; i < 4; i++) {
        catTotalRow.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(lightGreyColor),
          textBrush: PdfSolidBrush(onSurfaceColor),
          font: boldFont,
          cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
          format: PdfStringFormat(
            alignment: i >= 2 ? PdfTextAlignment.right : (i == 1 ? PdfTextAlignment.center : PdfTextAlignment.left),
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      categoryGrid.draw(
        page: page1,
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, pageSize.height - currentY),
      );

      PdfPage page2 = document.pages.add();
      final Size page2Size = page2.getClientSize();
      double page2Y = 10;

      page2.graphics.drawString(
        'Série Mensal e Histórico de Tendência',
        headerFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, page2Y, page2Size.width, 25),
      );
      page2Y += 30;

      final PdfGrid seriesGrid = PdfGrid();
      seriesGrid.repeatHeader = true;
      seriesGrid.columns.add(count: 4);
      final PdfGridRow seriesHeader = seriesGrid.headers.add(1)[0];
      seriesHeader.cells[0].value = 'Mês';
      seriesHeader.cells[1].value = 'Receitas (R\$)';
      seriesHeader.cells[2].value = 'Despesas (R\$)';
      seriesHeader.cells[3].value = 'Saldo (R\$)';

      for (int i = 0; i < 4; i++) {
        seriesHeader.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(primaryColor),
          textBrush: PdfSolidBrush(surfaceColor),
          font: boldFont,
          cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
          format: PdfStringFormat(
            alignment: i == 0 ? PdfTextAlignment.left : PdfTextAlignment.right,
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      for (final point in snap.monthlySeries) {
        final row = seriesGrid.rows.add();
        row.cells[0].value = point.label;
        row.cells[1].value = currencyFormat.format(point.incomeAmount.amountMinor / 100.0);
        row.cells[2].value = currencyFormat.format(point.expenseAmount.amountMinor / 100.0);
        row.cells[3].value = currencyFormat.format(point.balanceAmount.amountMinor / 100.0);

        for (int i = 0; i < 4; i++) {
          row.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(
              snap.monthlySeries.indexOf(point) % 2 == 0 ? surfaceColor : lightGreyColor,
            ),
            textBrush: PdfSolidBrush(onSurfaceColor),
            font: font,
            cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
            format: PdfStringFormat(
              alignment: i == 0 ? PdfTextAlignment.left : PdfTextAlignment.right,
              lineAlignment: PdfVerticalAlignment.middle,
            ),
          );
        }
      }

      seriesGrid.draw(
        page: page2,
        bounds: Rect.fromLTWH(0, page2Y, page2Size.width, page2Size.height - page2Y),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_analysis_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      if (!context.mounted) return;

      final params = ShareParams(
        files: [XFile(filePath)],
        text: 'Relatório de Análise',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (!context.mounted) return;
      SnackbarService.showError(
        context,
        'Falha ao gerar relatório de análise: $e',
        title: 'Erro Exportação PDF',
      );
    }
  }

  Size _calculatePdfImageSize(Size imageSize, Size maxSize) {
    final double imageAspectRatio = imageSize.width / imageSize.height;
    double drawWidth = maxSize.width;
    double drawHeight = drawWidth / imageAspectRatio;

    if (drawHeight > maxSize.height) {
      drawHeight = maxSize.height;
      drawWidth = drawHeight * imageAspectRatio;
    }

    return Size(drawWidth, drawHeight);
  }
}
