import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../res/app_resources.dart';

class ExcelInvoiceService {
  /// توليد الفاتورة بصيغة Excel
  static Future<List<int>?> generateInvoice(OrderModel order, {String langCode = 'ar'}) async {
    try {
      var excel = Excel.createExcel();
      var sheetName = AppStrings.get(null, 'invoice_sheet_name', langCode: langCode);
      var sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);
      // حذف الشيت الافتراضي إذا كان موجوداً
      if (excel.tables.keys.contains('Sheet1') && sheetName != 'Sheet1') {
        excel.delete('Sheet1');
      }

      // ─── تنسيقات ───
      var headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#8B5CF6'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      var titleStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 18,
      );

      // ─── بيانات الفاتورة الأساسية ───
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(AppStrings.get(null, 'invoice_title', langCode: langCode));
      titleCell.cellStyle = titleStyle;

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(AppStrings.get(null, 'invoice_order_id', langCode: langCode));
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(order.id);

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(AppStrings.get(null, 'invoice_date', langCode: langCode));
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt);
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(dateStr);

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(AppStrings.get(null, 'invoice_customer_name', langCode: langCode));
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(order.customerName);

      sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(AppStrings.get(null, 'invoice_customer_phone', langCode: langCode));
      sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue(order.customerPhone);

      sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(AppStrings.get(null, 'invoice_address', langCode: langCode));
      sheet.cell(CellIndex.indexByString('B7')).value = TextCellValue(order.customerAddress);

      // ─── جدول المنتجات ───
      int rowIdx = 9;
      
      // رؤوس الأعمدة
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_serial', langCode: langCode))
        ..cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_product_name', langCode: langCode))
        ..cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_quantity', langCode: langCode))
        ..cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_price_sar', langCode: langCode))
        ..cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_total', langCode: langCode))
        ..cellStyle = headerStyle;

      rowIdx++;

      // إضافة المنتجات
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = TextCellValue(item.productName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = IntCellValue(item.quantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = DoubleCellValue(item.price);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = DoubleCellValue(item.total);
        rowIdx++;
      }

      rowIdx++;
      
      // المجموع الكلي
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx))
        ..value = TextCellValue(AppStrings.get(null, 'invoice_grand_total', langCode: langCode))
        ..cellStyle = CellStyle(bold: true);
        
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx))
        ..value = DoubleCellValue(order.totalAmount)
        ..cellStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#8B5CF6'));

      return excel.save();
    } catch (e) {
      debugPrint('Error generating excel: $e');
      return null;
    }
  }
}
