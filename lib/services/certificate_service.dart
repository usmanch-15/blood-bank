import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'storage_service.dart';

class CertificateService {
  final StorageService _storageService = StorageService();

  Future<String> generateAndUpload({
    required String donorName,
    required String bloodGroup,
    required String donationDate,
    required String donorId,
    required String donationId,
  }) async {
    final pdf = pw.Document();

    // ✅ NEW: QR code encodes donationId — koi bhi is certificate ko scan
    // karke verify kar sakta hai ke ye record asal mein Firestore mein
    // maujood hai (fake/edited certificate se bachne ke liye).
    final verificationData = 'BLOODBANK-CERT:$donationId';
    const darkRed = PdfColor.fromInt(0xFF8B0000);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: darkRed, width: 3),
          ),
          margin: const pw.EdgeInsets.all(16),
          padding: const pw.EdgeInsets.all(32),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'DONATION ACKNOWLEDGEMENT',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: darkRed,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(width: 120, height: 2, color: darkRed),
                pw.SizedBox(height: 28),
                pw.Text('This certifies that',
                    style: const pw.TextStyle(fontSize: 15)),
                pw.SizedBox(height: 8),
                pw.Text(donorName,
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('has a confirmed donation recorded in Smart Blood Bank',
                    style: const pw.TextStyle(fontSize: 15)),
                pw.SizedBox(height: 22),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _infoBox('Blood Group', bloodGroup, darkRed),
                    pw.SizedBox(width: 24),
                    _infoBox('Date', donationDate, darkRed),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: verificationData,
                  width: 70,
                  height: 70,
                ),
                pw.SizedBox(height: 6),
                pw.Text('Record ID: $donationId — not a medical credential',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Smart Blood Bank - COMSATS University Islamabad, Vehari Campus',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return await _storageService.uploadCertificate(
      bytes: await pdf.save(),
      donorId: donorId,
      donationId: donationId,
    );
  }

  pw.Widget _infoBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
