import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile picture
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      // Create reference
      final ref = _storage.ref().child('user_profile_images/$uid.jpg');

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
