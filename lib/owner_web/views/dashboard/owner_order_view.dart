import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../viewmodels/owner_order_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../../models/order_model.dart';
import '../../../services/excel_invoice_service.dart';
import '../../../res/app_resources.dart';
import '../../../services/language_provider.dart';

class OwnerOrderView extends StatelessWidget {
  const OwnerOrderView({super.key});

  Future<void> _exportInvoice(BuildContext context, OrderModel order) async {
    try {
      final langCode = context.read<LanguageProvider>().currentLocale.languageCode;
      final bytes = await ExcelInvoiceService.generateInvoice(order, langCode: langCode);
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.get(context, 'invoice_generation_failed'))),
          );
        }
        return;
      }

      // تحديد اسم الملف الافتراضي
      final dateStr = intl.DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      // تنظيف اسم العميل من الرموز التي قد تمنع حفظ الملف
      final cleanName = order.customerName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final defaultFileName = '${cleanName}_$dateStr.xlsx';

      // استخدام file_picker لحفظ الملف (مطلوب تمرير bytes في أندرويد)
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: AppStrings.get(context, 'save_invoice'),
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (outputFile == null) {
        // المستخدم ألغى عملية الحفظ
        return;
      }

      // في أنظمة الديسكتوب، saveFile يرجع المسار فقط وعلينا حفظه يدوياً
      // أما في أندرويد و iOS، فبمجرد تمرير bytes يتم حفظه ولا نحتاج لعمل write مرة أخرى 
      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(context, 'invoice_saved_success').replaceFirst('{path}', outputFile),
                style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'save_error').replaceFirst('{error}', e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.get(context, 'manage_orders_title'),
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<OwnerOrderViewModel>(
        builder: (context, vm, _) {
          // عرض رسالة النجاح / الخطأ من الـ ViewModel
          if (vm.message != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.parseMessage(context, vm.message!),
                      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onPrimary)),
                  backgroundColor: vm.message!.contains('error') || vm.message!.contains('error_msg')
                      ? Colors.red.shade700
                      : const Color(0xFF8B5CF6),
                ),
              );
              vm.message = null;
            });
          }
          return StreamBuilder<List<OrderModel>>(
            stream: vm.ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(AppStrings.parseMessage(context, 'error_msg|${snapshot.error}'),
                      style: GoogleFonts.cairo(color: Colors.red)),
                );
              }

              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Text(AppStrings.get(context, 'no_orders_currently'),
                      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 18)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(
                    order: order,
                    onAccept: () => vm.acceptOrder(order, context.read<ProductViewModel>()),
                    onCancel: () => vm.cancelOrder(order, context.read<ProductViewModel>()),
                    onPrint: () => _exportInvoice(context, order),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onPrint;

  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.onCancel,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.accepted:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    final dateStr = intl.DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt);

    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.status.getLabel(context),
                    style: GoogleFonts.cairo(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${AppStrings.get(context, 'order_id')}${order.id.substring(0, 8)}',
                  style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            Text('${AppStrings.get(context, 'customer')}: ${order.customerName} - ${order.customerPhone}',
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            Text('${AppStrings.get(context, 'date')}: $dateStr',
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            if (order.notes != null && order.notes!.isNotEmpty)
              Text('${AppStrings.get(context, 'notes_label')}: ${order.notes}',
                  style: GoogleFonts.cairo(color: Colors.orangeAccent)),
            const SizedBox(height: 12),
            Text(
              '${AppStrings.get(context, 'items_count').replaceFirst('{count}', order.totalItems.toString())}:',
              style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
            ...order.items.map((item) => Text(
                  '${item.quantity}x ${item.productName} (${item.price} ${AppStrings.get(context, 'currency')})',
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.get(context, 'total')}: ${order.totalAmount} ${AppStrings.get(context, 'currency')}',
                  style: GoogleFonts.cairo(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status == OrderStatus.accepted)
                  ElevatedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print, size: 18),
                    label: Text(AppStrings.get(context, 'print_invoice'), style: GoogleFonts.cairo()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                const SizedBox(width: 8),
                if (order.status == OrderStatus.pending) ...[
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(AppStrings.get(context, 'accept'), style: GoogleFonts.cairo(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text(AppStrings.get(context, 'cancel'), style: GoogleFonts.cairo(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
