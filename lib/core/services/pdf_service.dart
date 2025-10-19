import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/widget_to_image.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/analysis/widgets/analysis_report_widget.dart';
import 'package:key_budget/features/analysis/widgets/category_analysis_section_widget.dart';
import 'package:key_budget/features/analysis/widgets/monthly_trend_section_widget.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<void> exportExpensesPdf(
      BuildContext context,
      List<Expense> expenses,
      AnalysisViewModel analysisViewModel,
      CategoryViewModel categoryViewModel) async {
    try {
      final PdfDocument document = PdfDocument();
      PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      double currentY = 0;

      final ByteData logoData = await rootBundle.load('assets/icon/logov2.png');
      final PdfBitmap logo = PdfBitmap(logoData.buffer.asUint8List());

      final ByteData fontData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final PdfFont font = PdfTrueTypeFont(fontData.buffer.asUint8List(), 10);
      final PdfFont headerFont = PdfTrueTypeFont(
          fontData.buffer.asUint8List(), 12,
          style: PdfFontStyle.bold);
      final PdfFont titleFont = PdfTrueTypeFont(
          fontData.buffer.asUint8List(), 18,
          style: PdfFontStyle.bold);

      final PdfColor primaryColor = PdfColor(
          AppTheme.primary.red, AppTheme.primary.green, AppTheme.primary.blue);
      final PdfColor onSurfaceColor = PdfColor(AppTheme.onSurface.red,
          AppTheme.onSurface.green, AppTheme.onSurface.blue);
      final PdfColor surfaceColor = PdfColor(
          AppTheme.surface.red, AppTheme.surface.green, AppTheme.surface.blue);
      final PdfColor lightGreyColor = PdfColor(
          AppTheme.surfaceContainerHighest.red,
          AppTheme.surfaceContainerHighest.green,
          AppTheme.surfaceContainerHighest.blue);

      page.graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 40, 40));
      page.graphics.drawString('Relatório de Despesas', titleFont,
          brush: PdfSolidBrush(primaryColor),
          bounds: Rect.fromLTWH(50, 5, pageSize.width - 50, 30));
      page.graphics.drawString(
          'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          font,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(50, 30, pageSize.width - 50, 20));
      currentY += 60;

      if (expenses.isNotEmpty) {
        page.graphics.drawString('Tabela de Despesas', headerFont,
            brush: PdfSolidBrush(onSurfaceColor),
            bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
        currentY += 25;

        final PdfGrid grid = PdfGrid();
        grid.columns.add(count: 5);
        grid.headers.add(1);
        final PdfGridRow header = grid.headers[0];
        header.cells[0].value = 'Data';
        header.cells[1].value = 'Valor (R\$)';
        header.cells[2].value = 'Categoria';
        header.cells[3].value = 'Motivação';
        header.cells[4].value = 'Local';

        for (int i = 0; i < header.cells.count; i++) {
          header.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(primaryColor),
            textBrush: PdfSolidBrush(surfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
                alignment: PdfTextAlignment.center,
                lineAlignment: PdfVerticalAlignment.middle),
          );
        }

        double totalAmount = 0;
        final currencyFormat =
            NumberFormat.currency(locale: 'pt_BR', symbol: '');
        for (var expense in expenses) {
          final PdfGridRow row = grid.rows.add();
          row.cells[0].value = DateFormat('dd/MM/yyyy').format(expense.date);
          row.cells[1].value = currencyFormat.format(expense.amount);
          final category =
              categoryViewModel.getCategoryById(expense.categoryId);
          row.cells[2].value = category?.name ?? 'N/A';
          row.cells[3].value = expense.motivation ?? '';
          row.cells[4].value = expense.location ?? '';
          totalAmount += expense.amount;

          for (int i = 0; i < row.cells.count; i++) {
            row.cells[i].style = PdfGridCellStyle(
              font: font,
              textBrush: PdfSolidBrush(onSurfaceColor),
              backgroundBrush: PdfSolidBrush(expenses.indexOf(expense) % 2 == 0
                  ? surfaceColor
                  : lightGreyColor),
              cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
              format: PdfStringFormat(
                  alignment:
                      i == 1 ? PdfTextAlignment.right : PdfTextAlignment.left,
                  lineAlignment: PdfVerticalAlignment.middle),
            );
          }
        }

        final PdfGridRow totalRow = grid.rows.add();
        totalRow.cells[0].value = 'Total';
        totalRow.cells[1].value = currencyFormat.format(totalAmount);
        for (int i = 2; i < totalRow.cells.count; i++) {
          totalRow.cells[i].value = '';
        }
        for (int i = 0; i < totalRow.cells.count; i++) {
          totalRow.cells[i].style = PdfGridCellStyle(
            backgroundBrush: PdfSolidBrush(primaryColor),
            textBrush: PdfSolidBrush(surfaceColor),
            font: headerFont,
            cellPadding: PdfPaddings(left: 5, right: 5, top: 5, bottom: 5),
            format: PdfStringFormat(
                alignment:
                    i == 1 ? PdfTextAlignment.right : PdfTextAlignment.left,
                lineAlignment: PdfVerticalAlignment.middle),
          );
        }

        final PdfLayoutResult? gridResult = grid.draw(
            page: page,
            bounds: Rect.fromLTWH(
                0, currentY, pageSize.width, pageSize.height - currentY));

        if (gridResult != null) {
          currentY = gridResult.bounds.bottom + 20;
          page = gridResult.page;
        } else {
          currentY += 200;
        }
      } else {
        page.graphics.drawString(
            'Nenhuma despesa no período selecionado.', font,
            brush: PdfSolidBrush(onSurfaceColor),
            bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
        currentY += 30;
      }

      if (currentY + 300 > pageSize.height) {
        page = document.pages.add();
        currentY = 0;
      }

      page.graphics.drawString('Gráficos de Análise', headerFont,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
      currentY += 30;

      final monthlyTrendKey = GlobalKey();
      final categoryAnalysisKey = GlobalKey();

      final monthlyTrendChart = Material(
          color: Colors.white,
          child: SizedBox(
            width: 500,
            child: MonthlyTrendSectionWidget(),
          ));
      final categoryAnalysisChart = Material(
          color: Colors.white,
          child: SizedBox(
            width: 500,
            child: CategoryAnalysisSectionWidget(),
          ));

      final monthlyTrendImageBytes =
          await WidgetToImage.captureWidgetFromProvider(
        context,
        ChangeNotifierProvider.value(
          value: analysisViewModel,
          child: Builder(
            key: monthlyTrendKey,
            builder: (ctx) =>
                Theme(data: Theme.of(ctx), child: monthlyTrendChart),
          ),
        ),
        wait: const Duration(milliseconds: 500),
      );

      final categoryAnalysisImageBytes =
          await WidgetToImage.captureWidgetFromProvider(
        context,
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: analysisViewModel),
            ChangeNotifierProvider.value(value: categoryViewModel),
          ],
          child: Builder(
            key: categoryAnalysisKey,
            builder: (ctx) =>
                Theme(data: Theme.of(ctx), child: categoryAnalysisChart),
          ),
        ),
        wait: const Duration(milliseconds: 500),
      );

      double availableHeight = pageSize.height - currentY;

      if (monthlyTrendImageBytes != null) {
        final PdfBitmap monthlyTrendImage = PdfBitmap(monthlyTrendImageBytes);
        final imageSize = Size(monthlyTrendImage.width.toDouble(),
            monthlyTrendImage.height.toDouble());
        final drawSize = _calculatePdfImageSize(
            imageSize, Size(pageSize.width * 0.9, availableHeight * 0.45));

        if (currentY + drawSize.height > pageSize.height) {
          page = document.pages.add();
          currentY = 0;
          availableHeight = pageSize.height;
        }

        page.graphics.drawImage(
            monthlyTrendImage,
            Rect.fromLTWH((pageSize.width - drawSize.width) / 2, currentY,
                drawSize.width, drawSize.height));
        currentY += drawSize.height + 20;
        availableHeight = pageSize.height - currentY;
      } else {
        page.graphics.drawString(
            'Erro ao gerar gráfico de tendência mensal.', font,
            brush: PdfSolidBrush(PdfColor(255, 0, 0)),
            bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
        currentY += 20;
        availableHeight = pageSize.height - currentY;
      }

      if (currentY + 150 > pageSize.height) {
        page = document.pages.add();
        currentY = 0;
        availableHeight = pageSize.height;
      }

      if (categoryAnalysisImageBytes != null) {
        final PdfBitmap categoryAnalysisImage =
            PdfBitmap(categoryAnalysisImageBytes);
        final imageSize = Size(categoryAnalysisImage.width.toDouble(),
            categoryAnalysisImage.height.toDouble());
        final drawSize = _calculatePdfImageSize(
            imageSize, Size(pageSize.width * 0.9, availableHeight * 0.8));

        if (currentY + drawSize.height > pageSize.height) {
          page = document.pages.add();
          currentY = 0;
        }

        page.graphics.drawImage(
            categoryAnalysisImage,
            Rect.fromLTWH((pageSize.width - drawSize.width) / 2, currentY,
                drawSize.width, drawSize.height));
      } else {
        page.graphics.drawString(
            'Erro ao gerar gráfico de análise por categoria.', font,
            brush: PdfSolidBrush(PdfColor(255, 0, 0)),
            bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
      }

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_expenses_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      await Share.shareXFiles([XFile(filePath)],
          text: 'Relatório de Despesas e Análise');
    } catch (e, s) {
      if (!context.mounted) return;
      debugPrint('Erro ao exportar PDF de despesas: $e\n$s');
      SnackbarService.showError(
          context, 'Falha ao gerar relatório de despesas: $e',
          title: 'Erro Exportação PDF');
    }
  }

  Future<void> exportCredentialsPdf(
      BuildContext context, CredentialViewModel credentialViewModel) async {
    try {
      final credentials = credentialViewModel.allCredentials;
      final PdfDocument document = PdfDocument();
      PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      double currentY = 0;

      final ByteData logoData = await rootBundle.load('assets/icon/logov2.png');
      final PdfBitmap logo = PdfBitmap(logoData.buffer.asUint8List());

      final ByteData fontData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final PdfFont font = PdfTrueTypeFont(fontData.buffer.asUint8List(), 8);
      final PdfFont headerFont = PdfTrueTypeFont(
          fontData.buffer.asUint8List(), 9,
          style: PdfFontStyle.bold);
      final PdfFont titleFont = PdfTrueTypeFont(
          fontData.buffer.asUint8List(), 18,
          style: PdfFontStyle.bold);

      final PdfColor primaryColor = PdfColor(
          AppTheme.primary.red, AppTheme.primary.green, AppTheme.primary.blue);
      final PdfColor onSurfaceColor = PdfColor(AppTheme.onSurface.red,
          AppTheme.onSurface.green, AppTheme.onSurface.blue);
      final PdfColor surfaceColor = PdfColor(
          AppTheme.surface.red, AppTheme.surface.green, AppTheme.surface.blue);
      final PdfColor lightGreyColor = PdfColor(
          AppTheme.surfaceContainerHighest.red,
          AppTheme.surfaceContainerHighest.green,
          AppTheme.surfaceContainerHighest.blue);

      page.graphics.drawImage(logo, const Rect.fromLTWH(0, 0, 40, 40));
      page.graphics.drawString('Relatório de Credenciais', titleFont,
          brush: PdfSolidBrush(primaryColor),
          bounds: Rect.fromLTWH(50, 5, pageSize.width - 50, 30));
      page.graphics.drawString(
          'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          font,
          brush: PdfSolidBrush(onSurfaceColor),
          bounds: Rect.fromLTWH(50, 30, pageSize.width - 50, 20));
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
        row.cells[2].value =
            credentialViewModel.decryptPassword(credential.encryptedPassword);
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
                      : lightGreyColor),
              cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4),
              format: PdfStringFormat(wordWrap: PdfWordWrapType.word));
          row.cells[i].stringFormat =
              PdfStringFormat(wordWrap: PdfWordWrapType.word);
        }
      }

      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 3, right: 3, top: 4, bottom: 4),
      );

      grid.draw(
          page: page,
          bounds: Rect.fromLTWH(
              0, currentY, pageSize.width, pageSize.height - currentY),
          format: PdfLayoutFormat(
            layoutType: PdfLayoutType.paginate,
            breakType: PdfLayoutBreakType.fitPage,
          ));

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_credentials_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      await Share.shareXFiles([XFile(filePath)],
          text: 'Relatório de Credenciais');
    } catch (e, s) {
      if (!context.mounted) return;
      debugPrint('Erro ao exportar PDF de credenciais: $e\n$s');
      SnackbarService.showError(
          context, 'Falha ao gerar relatório de credenciais: $e',
          title: 'Erro Exportação PDF');
    }
  }

  Future<void> exportAnalysisPdf(
      BuildContext context, AnalysisViewModel analysisViewModel) async {
    try {
      final Widget reportWidget = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: analysisViewModel),
              ChangeNotifierProvider.value(
                  value: context.read<CategoryViewModel>()),
            ],
            child: Builder(
              builder: (ctx) => Theme(
                data: Theme.of(ctx),
                child: Container(
                  color: Colors.white,
                  child: SizedBox(
                      width: 600,
                      child: SingleChildScrollView(
                        child: AnalysisReportWidget(
                            analysisViewModel: analysisViewModel),
                      )),
                ),
              ),
            ),
          ),
        ),
      );

      final Uint8List? imageBytes = await WidgetToImage.captureWidget(
        context,
        reportWidget,
        wait: const Duration(milliseconds: 1500),
      );

      if (imageBytes == null) {
        if (!context.mounted) return;
        SnackbarService.showError(
            context, 'Falha ao capturar imagem do relatório.',
            title: 'Erro Exportação PDF');
        return;
      }

      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      final PdfBitmap image = PdfBitmap(imageBytes);

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final drawSize = _calculatePdfImageSize(imageSize, pageSize);

      page.graphics.drawImage(
          image,
          Rect.fromLTWH((pageSize.width - drawSize.width) / 2, 0,
              drawSize.width, drawSize.height));

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final fileName =
          'keybudget_analysis_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(Uint8List.fromList(bytes));

      await Share.shareXFiles([XFile(filePath)], text: 'Relatório de Análise');
    } catch (e, s) {
      if (!context.mounted) return;
      debugPrint('Erro ao exportar PDF de análise: $e\n$s');
      SnackbarService.showError(
          context, 'Falha ao gerar relatório de análise: $e',
          title: 'Erro Exportação PDF');
    }
  }

  Size _calculatePdfImageSize(Size imageSize, Size pageSize) {
    final double imageAspectRatio = imageSize.width / imageSize.height;
    double drawWidth;
    double drawHeight;

    drawWidth = pageSize.width;
    drawHeight = drawWidth / imageAspectRatio;

    if (drawHeight > pageSize.height) {
      drawHeight = pageSize.height;
      drawWidth = drawHeight * imageAspectRatio;
    }

    return Size(drawWidth, drawHeight);
  }
}
