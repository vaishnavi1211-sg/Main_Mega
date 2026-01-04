import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ReportingPage extends StatefulWidget {  
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final Color themePrimary = const Color(0xFF2563EB);
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _enterpriseNameController = TextEditingController();
  
  Uint8List? _selfieBytes;
  Uint8List? _meterPhotoBytes;
  XFile? _selfieFile;
  XFile? _meterFile;
  bool _isSubmitting = false;

  // Add this to track if submission was successful
  bool _submissionSuccessful = false;

  Future<void> _pickFromGallery(bool isSelfie) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, 
        maxWidth: 1200,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          if (isSelfie) {
            _selfieBytes = bytes;
            _selfieFile = image;
          } else {
            _meterPhotoBytes = bytes;
            _meterFile = image;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> _uploadImage(XFile xFile, String folderName) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().replaceAll('[', '').replaceAll(']', '')}.jpg';
      final String path = '$folderName/$fileName';
      final bytes = await xFile.readAsBytes();
      
      await supabase.storage.from('manager_uploads').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      return supabase.storage.from('manager_uploads').getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> _submitVisitReport() async {
    if (_enterpriseNameController.text.isEmpty || _selfieFile == null || _meterFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields and 2 photos are required!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String? selfieUrl = await _uploadImage(_selfieFile!, 'selfies');
      final String? meterUrl = await _uploadImage(_meterFile!, 'meters');

      if (selfieUrl == null || meterUrl == null) throw "Could not upload photos.";

      await supabase.from('manager_visits').insert({
        'enterprise_name': _enterpriseNameController.text.trim(),
        'selfie_url': selfieUrl,
        'meter_photo_url': meterUrl,
        'visit_time': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _submissionSuccessful = true);
        _showSuccess();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

 void _showSuccess() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
      content: const Text("Visit report submitted successfully!", textAlign: TextAlign.center),
      actions: [
        Center(
          child: TextButton(
            onPressed: () {
              // Just close the dialog and pop the current page
              Navigator.pop(ctx); // Close dialog
              Navigator.pushNamed(context, '/marketingManagerDashboard');            },
            child: const Text("OK"),
          ),
        )
      ],
    ),
  );
}

  void _clearForm() {
    setState(() {
      _enterpriseNameController.clear();
      _selfieBytes = null;
      _meterPhotoBytes = null;
      _selfieFile = null;
      _meterFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If submission was successful, allow going back
        if (_submissionSuccessful) {
          _clearForm();
          return true;
        }
        
        // Otherwise ask for confirmation
        final shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  _clearForm();
                  Navigator.pop(context, true);
                },
                child: const Text('DISCARD'),
              ),
            ],
          ),
        );
        
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: themePrimary,
          elevation: 0,
          title: Text("Field Visit Entry", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Check if form has data
              if (_enterpriseNameController.text.isNotEmpty || 
                  _selfieFile != null || 
                  _meterFile != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Unsaved Changes'),
                    content: const Text('Going back will discard your form data. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('STAY'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('LEAVE'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isSubmitting 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Shop / Enterprise Name"),
                  _buildTextField(),
                  
                  const SizedBox(height: 30),
                  
                  _buildLabel("Required Photo Proofs (Gallery)"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildPhotoTile("Selfie", _selfieBytes, () => _pickFromGallery(true))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPhotoTile("Meter Photo", _meterPhotoBytes, () => _pickFromGallery(false))),
                    ],
                  ),
                  
                  const SizedBox(height: 50),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitVisitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("SUBMIT REPORT", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey[900]));
  }

  Widget _buildTextField() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: _enterpriseNameController,
        decoration: const InputDecoration(hintText: "Enter Name", border: InputBorder.none),
      ),
    );
  }

  Widget _buildPhotoTile(String label, Uint8List? bytes, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bytes != null ? Colors.green : Colors.grey.shade300, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null 
          ? Image.memory(bytes, fit: BoxFit.cover) 
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_search, color: Colors.blueAccent, size: 35),
                const SizedBox(height: 10),
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
      ),
    );
  }
}








