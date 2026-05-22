import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
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

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Blood Donation Certificate',
                  style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Text('This certifies that',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(donorName,
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('has successfully donated blood',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Blood Group: $bloodGroup',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Date: $donationDate',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 30),
              pw.Text('Smart Blood Bank – COMSATS University Islamabad',
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$donationId.pdf');
    await file.writeAsBytes(await pdf.save());

    return await _storageService.uploadCertificate(
      file: file,
      donorId: donorId,
      donationId: donationId,
    );
  }
}