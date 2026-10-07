import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadCertificate({
    required Uint8List bytes,
    required String donorId,
    required String donationId,
  }) async {
    final ref = _storage.ref().child(
      '${AppConstants.certificatesPath}/$donorId/$donationId/certificate.pdf',
    );
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String userId,
  }) async {
    if (bytes.isEmpty || bytes.length >= 3 * 1024 * 1024) {
      throw ArgumentError('Choose an image smaller than 3 MB.');
    }
    final ref = _storage.ref().child(
      '${AppConstants.profileImagesPath}/$userId/avatar.jpg',
    );
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await task.ref.getDownloadURL();
    return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }
}
