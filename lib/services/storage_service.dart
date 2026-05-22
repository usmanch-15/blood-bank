import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadCertificate({
    required File file,
    required String donorId,
    required String donationId,
  }) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.certificatesPath}/$donorId/$donationId.pdf');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.profileImagesPath}/$userId/avatar.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }
}