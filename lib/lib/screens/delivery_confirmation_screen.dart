import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/delivery_order.dart';
import '../services/delivery_service.dart';
import '../services/firebase_storage_service.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryConfirmationScreen({super.key, required this.order});

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final GlobalKey<_SignaturePadState> _signatureKey = GlobalKey<_SignaturePadState>();
  final GlobalKey<_SignaturePadState> _signaturePadKey = GlobalKey<_SignaturePadState>();
  final TextEditingController _confirmationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String? _signaturePath;
  String? _photoPath;
  String? _uploadedPhotoUrl; // Store the Firebase Storage URL for uploaded photo
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _confirmationController.text = 'Parts delivered successfully to ${widget.order.mechanicName} at ${widget.order.workshopName}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Delivery - ${widget.order.orderNumber}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(),
              const SizedBox(height: 20),
              _buildConfirmationText(),
              const SizedBox(height: 20),
              _buildSignatureSection(),
              const SizedBox(height: 20),
              _buildPhotoSection(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Order: ${widget.order.orderNumber}'),
            Text('Workshop: ${widget.order.workshopName}'),
            Text('Mechanic: ${widget.order.mechanicName}'),
            Text('Bay: ${widget.order.bayNumber}'),
            Text('Parts: ${widget.order.parts.length} items'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationText() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Confirmation *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide details about the delivery completion:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmationController,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Confirmation details are required';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more detailed confirmation (at least 10 characters)';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Confirmation Details *',
                hintText: 'Describe the delivery completion, any issues, or additional notes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Minimum 10 characters required',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Digital Signature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _signaturePath != null ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _signaturePath != null ? '✓ REQUIRED' : '✗ REQUIRED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_signaturePath != null)
                  IconButton(
                    onPressed: _clearSignature,
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Clear Signature',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide a signature to confirm delivery receipt:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _signaturePath != null ? Colors.green : Colors.red,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _signaturePath != null
                  ? Image.file(File(_signaturePath!), fit: BoxFit.contain)
                  : RepaintBoundary(
                      key: _signatureKey,
                      child: SignaturePad(),
                    ),
            ),
            const SizedBox(height: 12),
            if (_signaturePath == null) ...[
              ElevatedButton.icon(
                onPressed: _captureSignature,
                icon: const Icon(Icons.edit),
                label: const Text('Capture Signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Delivery Photo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _photoPath != null ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _photoPath != null ? '✓ OPTIONAL' : '○ OPTIONAL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_photoPath != null)
                  IconButton(
                    onPressed: _clearPhoto,
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Clear Photo',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Optional: Take or select a photo to document the delivery:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _photoPath != null ? Colors.blue : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploadedPhotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _uploadedPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    )
                  : _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                        )
                      : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No photo captured',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'Photo is optional for delivery confirmation',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _photoPath != null ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isFormComplete = _confirmationController.text.trim().isNotEmpty && 
                          _confirmationController.text.trim().length >= 10 &&
                          _signaturePath != null;
    
    return Column(
      children: [
        // Status indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFormComplete ? Colors.green[50] : Colors.red[50],
            border: Border.all(
              color: isFormComplete ? Colors.green : Colors.red,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isFormComplete ? Icons.check_circle : Icons.warning,
                color: isFormComplete ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFormComplete 
                      ? '✅ All required fields completed. Ready to confirm delivery!'
                      : '⚠️ Please complete all required fields: Confirmation text (✓), Signature (${_signaturePath != null ? '✓' : '✗'})',
                  style: TextStyle(
                    color: isFormComplete ? Colors.green[700] : Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Upload progress indicator
        if (_isLoading && _uploadProgress > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_upload, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uploading files to Firebase Storage...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ],
            ),
          ),
        ],
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isLoading || !isFormComplete) ? null : _submitConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFormComplete ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: _isLoading
                ? const Text(
                    'Confirming Delivery...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                : Text(
                    isFormComplete 
                        ? 'CONFIRM DELIVERY & UPDATE STATUS'
                        : 'COMPLETE REQUIRED FIELDS FIRST',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  void _captureSignature() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Sign Here',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RepaintBoundary(
                    key: _signaturePadKey,
                    child: SignaturePad(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Clear signature
                      _signaturePadKey.currentState?.clearSignature();
                    },
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Capture signature before closing dialog
                      await _saveSignatureFromDialog();
                      Navigator.pop(context);
                      // Show success message after dialog closes
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signature captured successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSignatureFromDialog() async {
    try {
      print("🔍 Attempting to capture signature...");
      
      // Get the boundary of the RepaintBoundary from the signature pad in the dialog
      if (_signaturePadKey.currentContext != null) {
        print("✅ Signature context found");
        
        RenderRepaintBoundary boundary = _signaturePadKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;

        print("✅ RepaintBoundary found, converting to image...");
        
        // Convert to image
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          print("✅ Image converted to bytes successfully");
          
          // Convert to Uint8List
          Uint8List pngBytes = byteData.buffer.asUint8List();

          // Save file into app's documents directory
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);

          await file.writeAsBytes(pngBytes);

          // Update state with the saved signature path
          if (mounted) {
            setState(() {
              _signaturePath = filePath;
            });
            print("✅ State updated with signature path: $filePath");
          }

          print("✅ Signature saved at: $filePath");
        } else {
          print("❌ Failed to convert image to bytes");
          throw Exception("Failed to convert signature to bytes");
        }
      } else {
        print("❌ Signature context not available");
        throw Exception("Signature context not available");
      }
    } catch (e) {
      print("❌ Error saving signature: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSignature() async {
    try {
      // Wait a bit to ensure the dialog is closed and context is available
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get the boundary of the RepaintBoundary from the signature pad in the dialog
      if (_signaturePadKey.currentContext != null) {
        RenderRepaintBoundary boundary = _signaturePadKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;

        // Convert to image
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          // Convert to Uint8List
          Uint8List pngBytes = byteData.buffer.asUint8List();

          // Save file into app's documents directory
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);

          await file.writeAsBytes(pngBytes);

          // Update state with the saved signature path
          if (mounted) {
            setState(() {
              _signaturePath = filePath;
            });
          }

          print("✅ Signature saved at: $filePath");
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature captured successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception("Failed to convert signature to bytes");
        }
      } else {
        throw Exception("Signature context not available");
      }
    } catch (e) {
      print("❌ Error saving signature: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _clearSignature() {
    setState(() {
      _signaturePath = null;
    });
  }


  void _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (photo != null && mounted) {
        setState(() {
          _photoPath = photo.path;
          _isLoading = true;
        });
        
        try {
          // Upload photo directly to Firebase Storage
          final photoUrl = await FirebaseStorageService.uploadPhoto(
            widget.order.id,
            photo.path,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );
          
          if (mounted) {
            setState(() {
              _uploadedPhotoUrl = photoUrl;
              _isLoading = false;
              _uploadProgress = 0.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Photo captured and uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _uploadProgress = 0.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error uploading photo: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (photo != null && mounted) {
        setState(() {
          _photoPath = photo.path;
          _isLoading = true;
        });
        
        try {
          // Upload photo directly to Firebase Storage
          final photoUrl = await FirebaseStorageService.uploadPhoto(
            widget.order.id,
            photo.path,
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );
          
          if (mounted) {
            setState(() {
              _uploadedPhotoUrl = photoUrl;
              _isLoading = false;
              _uploadProgress = 0.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📷 Photo selected and uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _uploadProgress = 0.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error uploading photo: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error selecting photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearPhoto() {
    setState(() {
      _photoPath = null;
      _uploadedPhotoUrl = null;
    });
  }

  void _submitConfirmation() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for confirmation text
    final confirmationText = _confirmationController.text.trim();
    if (confirmationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter confirmation details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required signature only
    if (_signaturePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✍️ Signature is required! Please provide a signature before confirming delivery.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show upload progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📤 Uploading signature and photo to Firebase Storage...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Always update status to delivered when confirming delivery
      await DeliveryService.updateDeliveryStatus(
        widget.order.id, 
        DeliveryStatus.delivered
      );

      // Try to upload files to Firebase Storage with fallback
      try {
        // Add delivery confirmation with Firebase Storage uploads and progress tracking
        await DeliveryService.addDeliveryConfirmation(
          widget.order.id,
          confirmationText,
          _signaturePath,
          _uploadedPhotoUrl != null ? null : _photoPath, // Use local path only if photo wasn't uploaded directly
          photoUrl: _uploadedPhotoUrl, // Pass the pre-uploaded photo URL
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Delivery confirmed successfully! Files uploaded to Firebase Storage. Status updated to DELIVERED'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (storageError) {
        print('⚠️ Firebase Storage error, using fallback: $storageError');
        
        // Fallback: Save confirmation without Firebase Storage
        await DeliveryService.addDeliveryConfirmationWithoutStorage(
          widget.order.id,
          confirmationText,
          _signaturePath,
          _uploadedPhotoUrl != null ? null : _photoPath, // Use local path only if photo wasn't uploaded directly
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Delivery confirmed! Status updated to DELIVERED (files saved locally)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        // Navigate back to the previous screen with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error confirming delivery: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset> points = [];
  List<List<Offset>> paths = [];

  void clearSignature() {
    setState(() {
      points.clear();
      paths.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: GestureDetector(
        onTap: () {
          // Tap detected
        },
        onPanStart: (details) {
          setState(() {
            points = [details.localPosition];
            paths.add([details.localPosition]);
          });
        },
        onPanUpdate: (details) {
          setState(() {
            points.add(details.localPosition);
            if (paths.isNotEmpty) {
              paths.last.add(details.localPosition);
            }
          });
        },
        onPanEnd: (details) {
          setState(() {
            points = []; // Clear temporary points for the next stroke
            // Don't clear paths - they should remain for drawing
          });
        },
        child: CustomPaint(
          key: ValueKey(paths.length), // Force repaint when paths change
          painter: SignaturePainter(paths),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> paths;

  SignaturePainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    
    if (paths.isEmpty) {
      // Draw a placeholder text when no signature
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Draw your signature here',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw each path
    for (int pathIndex = 0; pathIndex < paths.length; pathIndex++) {
      List<Offset> path = paths[pathIndex];
      if (path.length > 1) {
        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      } else if (path.length == 1) {
        // Draw a dot for single points
        canvas.drawCircle(path[0], 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    bool shouldRepaint = oldDelegate.paths.length != paths.length;
    if (!shouldRepaint) {
      for (int i = 0; i < paths.length; i++) {
        if (oldDelegate.paths[i].length != paths[i].length) {
          shouldRepaint = true;
          break;
        }
      }
    }
    return shouldRepaint;
  }
}
