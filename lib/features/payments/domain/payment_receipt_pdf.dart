import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';

class PaymentReceiptPdf {
  static Future<Uint8List> generate(PaymentRecord payment) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt.toLocal());
    final amountFormatted = 'Rs. ${PaymentRecord.formatIndianCurrency(payment.amountPaise).replaceAll('₹', '')}';
    final feeFormatted = 'Rs. ${PaymentRecord.formatIndianCurrency(payment.platformFeePaise).replaceAll('₹', '')}';
    final baseAmountFormatted = 'Rs. ${PaymentRecord.formatIndianCurrency(
      payment.amountPaise - payment.platformFeePaise,
    ).replaceAll('₹', '')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Brand Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('0D6548'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'UDYOGA SETHU',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Official Payment Receipt & Escrow Certificate',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        payment.status.name.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('0D6548'),
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Metadata Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECEIPT NUMBER', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(payment.receiptNo, style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DATE & TIME', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),

              pw.Divider(color: PdfColors.grey300, thickness: 1, height: 24),

              // Transaction & Counterparty Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PAYMENT METHOD', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(payment.method.displayName, style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TRANSACTION REF', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        payment.razorpayPaymentId ?? payment.razorpayOrderId ?? payment.id.substring(0, 16),
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Escrow Protection Certificate Banner
              if (payment.protected)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('E6F4EA'),
                    border: pw.Border.all(color: PdfColor.fromHex('0D6548'), width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ESCROW SECURED PAYMENT',
                              style: pw.TextStyle(
                                color: PdfColor.fromHex('0D6548'),
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Funds are held securely in the UdyogaSethu Escrow Vault. Release occurs automatically upon two-step job completion verification.',
                              style: pw.TextStyle(
                                color: PdfColor.fromHex('0D6548'),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              pw.SizedBox(height: 24),

              // Itemized Table
              pw.Text('ITEMIZED CHARGES', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Type', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Agreed Daily Wage / Order Total', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Service', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(baseAmountFormatted, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('UdyogaSethu Platform Fee & GST', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Platform', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(feeFormatted, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  if (payment.protected)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Safety & Escrow Protection Plan', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Protection', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Included', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Paid', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('INR', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(amountFormatted, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromHex('0D6548')))),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer Verification
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UdyogaSethu Trust & Payments Network', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                  pw.Text('Cryptographically verified by Supabase & Razorpay', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> shareReceipt(PaymentRecord payment) async {
    final pdfBytes = await generate(payment);
    final fileName = 'Receipt_${payment.receiptNo}.pdf';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            pdfBytes,
            name: fileName,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'UdyogaSethu Payment Receipt - ${payment.receiptNo}',
        text: 'Payment Receipt ${payment.receiptNo} of ${PaymentRecord.formatIndianCurrency(payment.amountPaise)} via UdyogaSethu.',
      ),
    );
  }
}
