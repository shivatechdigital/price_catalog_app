import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  // ═══════════════════════════════════════
  // SHARE FILE (WhatsApp, Email, etc.)
  // ═══════════════════════════════════════
  static Future<void> shareFile({
    required File file,
    required String subject,
    required String text,
    BuildContext? context,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: text,
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  // ═══════════════════════════════════════
  // SHARE VIA WHATSAPP
  // ═══════════════════════════════════════
  static Future<void> shareViaWhatsApp({
    required File file,
    required String message,
    String? phoneNumber,
  }) async {
    try {
      if (phoneNumber != null) {
        // Direct WhatsApp share to specific number
        final cleanPhone = phoneNumber.replaceAll(
          RegExp(r'[^\d]'),
          '',
        );
        final encodedMessage = Uri.encodeComponent(message);
        final whatsappUrl =
            'whatsapp://send?phone=91$cleanPhone&text=$encodedMessage';

        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl));
        }
      } else {
        // Share to any WhatsApp contact
        await Share.shareXFiles(
          [XFile(file.path)],
          text: message,
        );
      }
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      // Fallback to general share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
      );
    }
  }

  // ═══════════════════════════════════════
  // SHARE TEXT VIA WHATSAPP
  // ═══════════════════════════════════════
  static Future<void> shareTextViaWhatsApp({
    required String message,
    String? phoneNumber,
  }) async {
    try {
      final cleanPhone = phoneNumber?.replaceAll(
            RegExp(r'[^\d]'),
            '',
          ) ??
          '';
      final encodedMessage = Uri.encodeComponent(message);

      String whatsappUrl;
      if (cleanPhone.isNotEmpty) {
        whatsappUrl =
            'whatsapp://send?phone=91$cleanPhone&text=$encodedMessage';
      } else {
        whatsappUrl = 'whatsapp://send?text=$encodedMessage';
      }

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        await launchUrl(
          Uri.parse(
            'https://wa.me/?text=$encodedMessage',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  // ═══════════════════════════════════════
  // SHARE PRICE LIST TEXT
  // ═══════════════════════════════════════
  static String generatePriceListText({
    required List products,
    required String companyName,
    String currency = '₹',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🏢 *$companyName*');
    buffer.writeln('📋 *Price List*');
    buffer.writeln(
      '📅 ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    buffer.writeln('─────────────────────');

    for (final product in products) {
      buffer.writeln('');
      buffer.writeln('🔹 *${product.name}*');
      buffer.writeln('   Code: ${product.productCode}');
      buffer.writeln(
        '   Price: $currency${product.currentPrice.sellingPrice.toStringAsFixed(0)}/${product.unit}',
      );
      buffer.writeln(
        '   Availability: ${_getAvailabilityEmoji(product.availability)} ${_getAvailabilityText(product.availability)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('─────────────────────');
    buffer.writeln('📞 Contact us for best prices!');
    return buffer.toString();
  }

  // ═══════════════════════════════════════
  // OPEN FILE
  // ═══════════════════════════════════════
  static Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }

  // ═══════════════════════════════════════
  // PRINT PDF
  // ═══════════════════════════════════════
  static Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfFile.readAsBytes(),
    );
  }

  // ═══════════════════════════════════════
  // SAVE TO DOWNLOADS
  // ═══════════════════════════════════════
  static Future<File?> saveToDownloads(File file) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      }

      final downloadsDir = await getDownloadsDirectory() ??
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final fileName = file.path.split('/').last;
      final savedFile = await file.copy(
        '${downloadsDir.path}/$fileName',
      );
      return savedFile;
    } catch (e) {
      debugPrint('Save to downloads error: $e');
      return null;
    }
  }

  static String _getAvailabilityEmoji(availability) {
    return switch (availability.toString()) {
      'ProductAvailability.inStock' => '✅',
      'ProductAvailability.outOfStock' => '❌',
      _ => '⚠️',
    };
  }

  static String _getAvailabilityText(availability) {
    return switch (availability.toString()) {
      'ProductAvailability.inStock' => 'In Stock',
      'ProductAvailability.outOfStock' => 'Out of Stock',
      _ => 'Limited',
    };
  }
}