import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Compress image to reduce upload size
  static Future<Uint8List> _compressImage(String imagePath, {int quality = 85, int maxWidth = 800}) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) return bytes;
    
    // Resize if too large
    img.Image resizedImage = image;
    if (image.width > maxWidth) {
      resizedImage = img.copyResize(image, width: maxWidth);
    }
    
    // Compress as JPEG for photos, PNG for signatures
    final compressedBytes = imagePath.contains('signature') 
        ? Uint8List.fromList(img.encodePng(resizedImage))
        : Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
    
    return compressedBytes;
  }

  // Upload signature to Firebase Storage with compression and progress
  static Future<String> uploadSignature(String orderId, String signaturePath, {Function(double)? onProgress}) async {
    try {
      print('🔄 Starting signature upload for order: $orderId');
      print('📁 Signature path: $signaturePath');
      
      // Check if file exists
      final file = File(signaturePath);
      if (!await file.exists()) {
        throw Exception('Signature file does not exist: $signaturePath');
      }
      
      print('🔄 Compressing signature...');
      final compressedBytes = await _compressImage(signaturePath, quality: 95, maxWidth: 600);
      print('📦 Compressed size: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB');
      
      final fileName = 'signature_${orderId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = 'delivery_files/$orderId/signatures/$fileName';
      print('🗂️ Storage path: $storagePath');
      
      final ref = _storage.ref().child(storagePath);
      
      final metadata = SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'public, max-age=31536000',
      );
      
      print('📤 Starting upload to Firebase Storage...');
      final uploadTask = ref.putData(compressedBytes, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        print('📤 Signature upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      print('✅ Upload completed, getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $downloadUrl');
      
      // Store metadata in Firestore
      print('💾 Storing metadata in Firestore...');
      await _firestore.collection('delivery_files').add({
        'orderId': orderId,
        'fileType': 'signature',
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'fileSize': compressedBytes.length,
        'storagePath': storagePath,
      });
      
      print('✅ Signature uploaded successfully: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading signature: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Upload photo to Firebase Storage with compression and progress
  static Future<String?> uploadPhoto(String orderId, String photoPath, {Function(double)? onProgress}) async {
    try {
      print('🔄 Starting photo upload for order: $orderId');
      print('📁 Photo path: $photoPath');
      
      // Check if file exists
      final file = File(photoPath);
      if (!await file.exists()) {
        throw Exception('Photo file does not exist: $photoPath');
      }
      
      print('🔄 Compressing photo...');
      final compressedBytes = await _compressImage(photoPath, quality: 80, maxWidth: 800);
      print('📦 Compressed size: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB');
      
      final fileName = 'photo_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'delivery_files/$orderId/photos/$fileName';
      print('🗂️ Storage path: $storagePath');
      
      final ref = _storage.ref().child(storagePath);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      
      print('📤 Starting upload to Firebase Storage...');
      final uploadTask = ref.putData(compressedBytes, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        print('📤 Photo upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      print('✅ Upload completed, getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $downloadUrl');
      
      // Store metadata in Firestore
      print('💾 Storing metadata in Firestore...');
      await _firestore.collection('delivery_files').add({
        'orderId': orderId,
        'fileType': 'photo',
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'fileSize': compressedBytes.length,
        'storagePath': storagePath,
      });
      
      print('✅ Photo uploaded successfully: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Get all files for a specific order
  static Future<List<Map<String, dynamic>>> getOrderFiles(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_files')
          .where('orderId', isEqualTo: orderId)
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting order files: $e');
      return [];
    }
  }

  // Delete a file from Firebase Storage and Firestore
  static Future<void> deleteFile(String fileId, String downloadUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection('delivery_files').doc(fileId).delete();
      
      // Delete from Firebase Storage
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  // Get signature for an order with better error handling
  static Future<String?> getOrderSignature(String orderId) async {
    try {
      print('🔍 Looking for signature for order: $orderId');
      
      // First try to get from the delivery order document directly
      try {
        final orderDoc = await _firestore.collection('delivery_orders').doc(orderId).get();
        if (orderDoc.exists) {
          final data = orderDoc.data() as Map<String, dynamic>?;
          final signatureUrl = data?['signatureUrl'] as String?;
          if (signatureUrl != null && signatureUrl.isNotEmpty) {
            print('✅ Signature found in order document: $signatureUrl');
            return signatureUrl;
          }
        }
      } catch (e) {
        print('⚠️ Could not check order document: $e');
      }
      
      // Fallback: check delivery_files collection
      try {
        final querySnapshot = await _firestore
            .collection('delivery_files')
            .where('orderId', isEqualTo: orderId)
            .where('fileType', isEqualTo: 'signature')
            .orderBy('uploadedAt', descending: true)
            .limit(1)
            .get();
        
        print('📊 Found ${querySnapshot.docs.length} signature documents in delivery_files');
        
        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final downloadUrl = data['downloadUrl'] as String?;
          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            print('✅ Signature found in delivery_files: $downloadUrl');
            return downloadUrl;
          }
        }
      } catch (e) {
        print('⚠️ Could not check delivery_files collection: $e');
      }
      
      print('ℹ️ No signature found for order: $orderId');
      return null;
    } catch (e) {
      print('❌ Error getting order signature: $e');
      // Return null instead of rethrowing to prevent crashes
      return null;
    }
  }

  // Get photos for an order
  static Future<List<String>> getOrderPhotos(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_files')
          .where('orderId', isEqualTo: orderId)
          .where('fileType', isEqualTo: 'photo')
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['downloadUrl'] as String)
          .toList();
    } catch (e) {
      print('Error getting order photos: $e');
      return [];
    }
  }
}
