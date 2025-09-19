import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/delivery_service.dart';

class DeliveryFilesScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const DeliveryFilesScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DeliveryFilesScreen> createState() => _DeliveryFilesScreenState();
}

class _DeliveryFilesScreenState extends State<DeliveryFilesScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get files from both Firebase Storage and local paths
      final List<Map<String, dynamic>> allFiles = [];
      
      // Get Firebase Storage files
      try {
        final firebaseFiles = await DeliveryService.getDeliveryFiles(widget.orderId);
        allFiles.addAll(firebaseFiles);
      } catch (e) {
        print('⚠️ Could not load Firebase Storage files: $e');
      }
      
      // Get local file paths from delivery order
      try {
        final paths = await DeliveryService.getDeliveryPaths(widget.orderId);
        print('🔍 Retrieved paths: $paths');
        
        // Add signature if exists
        if (paths['signaturePath'] != null && paths['signaturePath'].toString().isNotEmpty) {
          print('✅ Adding signature: ${paths['signaturePath']}');
          allFiles.add({
            'fileType': 'signature',
            'fileName': 'signature.png',
            'downloadUrl': null,
            'localPath': paths['signaturePath'],
            'uploadedAt': DateTime.now(),
            'fileSize': 0,
            'source': 'local',
          });
        } else {
          print('❌ No signature path found');
        }
        
        // Add photo if exists
        if (paths['photoPath'] != null && paths['photoPath'].toString().isNotEmpty) {
          print('✅ Adding photo: ${paths['photoPath']}');
          allFiles.add({
            'fileType': 'photo',
            'fileName': 'photo.jpg',
            'downloadUrl': null,
            'localPath': paths['photoPath'],
            'uploadedAt': DateTime.now(),
            'fileSize': 0,
            'source': 'local',
          });
        } else {
          print('❌ No photo path found');
        }
      } catch (e) {
        print('⚠️ Could not load local file paths: $e');
      }
      
      print('📊 Total files loaded: ${allFiles.length}');
      for (int i = 0; i < allFiles.length; i++) {
        print('📄 File $i: ${allFiles[i]}');
      }
      
      setState(() {
        _files = allFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Files - ${widget.orderNumber}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading delivery files...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No files found for this delivery'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFiles,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileType = file['fileType'] as String;
    final fileName = file['fileName'] as String;
    final downloadUrl = file['downloadUrl'] as String?;
    final localPath = file['localPath'] as String?;
    final uploadedAt = file['uploadedAt'] as dynamic;
    final fileSize = file['fileSize'] as int?;
    final source = file['source'] as String? ?? 'firebase';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  fileType == 'signature' ? Icons.edit : Icons.photo,
                  color: fileType == 'signature' ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileType == 'signature' ? 'Digital Signature' : 'Delivery Photo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: source == 'local' ? Colors.orange : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        source == 'local' ? 'LOCAL' : 'CLOUD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: fileType == 'signature' ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        fileType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (fileSize != null && fileSize > 0) ...[
              Text(
                'Size: ${_formatFileSize(fileSize)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Uploaded: ${_formatDate(uploadedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            // File preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(downloadUrl ?? '', localPath ?? '', fileType),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFullScreen(downloadUrl ?? '', localPath ?? '', fileType),
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('View Full Screen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadFile(downloadUrl ?? '', fileName),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _downloadFile(String downloadUrl, String fileName) {
    // In a real app, you would implement actual file download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download started: $fileName'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildImagePreview(String downloadUrl, String localPath, String fileType) {
    print('🖼️ Building image preview for $fileType');
    print('📡 Download URL: $downloadUrl');
    print('📁 Local path: $localPath');
    
    // Try Firebase Storage URL first, then local path
    if (downloadUrl.isNotEmpty) {
      print('🌐 Using Firebase URL');
      return CachedNetworkImage(
        imageUrl: downloadUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          print('❌ Firebase image failed: $error');
          return _buildLocalImagePreview(localPath, fileType);
        },
      );
    } else if (localPath.isNotEmpty) {
      print('📱 Using local path');
      return _buildLocalImagePreview(localPath, fileType);
    } else {
      print('❌ No image sources available');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(height: 8),
            Text('No image available'),
          ],
        ),
      );
    }
  }

  Widget _buildLocalImagePreview(String localPath, String fileType) {
    print('📱 Building local image preview for $fileType');
    print('📁 Local path: $localPath');
    
    try {
      final file = File(localPath);
      print('📄 File exists: ${file.existsSync()}');
      print('📄 File size: ${file.lengthSync()} bytes');
      
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Local image error: $error');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 8),
                Text('Failed to load local image'),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Local image exception: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(height: 8),
            Text('Invalid file path'),
          ],
        ),
      );
    }
  }

  void _viewFullScreen(String downloadUrl, String localPath, String fileType) {
    String title = fileType == 'signature' ? 'Digital Signature' : 'Delivery Photo';
    
    // If no Firebase URL, try local path
    if (downloadUrl.isEmpty) {
      if (localPath.isNotEmpty) {
        // For local files, we'll show them in a different viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocalImageViewer(
              imagePath: localPath,
              title: title,
            ),
          ),
        );
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image available to view'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: downloadUrl,
          title: title,
        ),
      ),
    );
  }
}

class LocalImageViewer extends StatelessWidget {
  final String imagePath;
  final String title;

  const LocalImageViewer({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('Failed to load image', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('Failed to load image', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
