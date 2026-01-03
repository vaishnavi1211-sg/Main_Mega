import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:provider/provider.dart';

class EmployeeAttendancePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const EmployeeAttendancePage({super.key, required this.cameras});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  XFile? _capturedImage;
  String _location = 'Fetching location...';
  File? _galleryImage;
  bool _showConfirmation = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _initializeCamera() async {
    try {
      if (widget.cameras.isNotEmpty) {
        _cameraController = CameraController(
          widget.cameras.first,
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        setState(() => _isCameraReady = true);
      } else {
        setState(() => _isCameraReady = false);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() => _isCameraReady = false);
    }
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _location = 'Location service disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && 
            permission != LocationPermission.always) {
          setState(() => _location = 'Location permission denied');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _location = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() => _location = 'Unable to fetch location');
    }
  }

  Future<void> _captureImage() async {
    if (_isCameraReady && !_isCapturing) {
      setState(() => _isCapturing = true);
      try {
        final image = await _cameraController!.takePicture();
        setState(() {
          _capturedImage = image;
          _galleryImage = null;
        });
      } catch (e) {
        debugPrint('Capture error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: GlobalColors.danger,
          ),
        );
      } finally {
        setState(() => _isCapturing = false);
      }
    } else if (!_isCameraReady) {
      // If camera not available, open gallery instead
      await _pickImageFromGallery();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _galleryImage = File(image.path);
          _capturedImage = null;
        });
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: GlobalColors.danger,
        ),
      );
    }
  }

  Future<void> _submitAttendance() async {
  final attendanceProvider = context.read<AttendanceProvider>();
  final employeeProvider = context.read<EmployeeProvider>();
  final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
  
  final imageFile = _galleryImage ?? (_capturedImage != null ? File(_capturedImage!.path) : null);
  
  if (imageFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please take or select a photo'),
        backgroundColor: GlobalColors.danger,
      ),
    );
    return;
  }

  try {
    // Upload image to Supabase Storage (if you have storage setup)
    // For now, we'll use a placeholder or save locally
    final fakeImageUrl = 'attendance_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await attendanceProvider.markAttendance(
      employeeName: empName,
      selfieUrl: fakeImageUrl,
      locationText: _location,
    );
    
    setState(() => _showConfirmation = true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to mark attendance: ${e.toString()}'),
        backgroundColor: GlobalColors.danger,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  void _resetAttendance() {
    setState(() {
      _capturedImage = null;
      _galleryImage = null;
      _showConfirmation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final now = DateTime.now();

    if (attendanceProvider.loading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showConfirmation) _buildConfirmationCard(now) else _buildAttendanceForm(),
              
              if (!_showConfirmation) ...[
                const SizedBox(height: 20),
                Text(
                  'Select or Capture Selfie',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Image picker options
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Camera Preview / Selected Image
                if (_isCameraReady && _capturedImage == null && _galleryImage == null)
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CameraPreview(_cameraController!),
                  )
                else if (_capturedImage != null || _galleryImage != null)
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File((_capturedImage?.path ?? _galleryImage?.path)!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 60, color: Colors.grey[400]),
                        SizedBox(height: 12),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Current Location
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: GlobalColors.primaryBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _location,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'MARK ATTENDANCE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceForm() {
    final employeeProvider = context.watch<EmployeeProvider>();
    final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Info Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GlobalColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: GlobalColors.primaryBlue),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      employeeProvider.profile?['position'] ?? 'Employee',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Date & Time Info
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, color: GlobalColors.primaryBlue),
                    SizedBox(height: 8),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.access_time, color: GlobalColors.primaryBlue),
                    SizedBox(height: 8),
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmationCard(DateTime timestamp) {
    final now = timestamp;
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: GlobalColors.success,
            ),
            SizedBox(height: 16),
            Text(
              'Attendance Marked Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GlobalColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            
            // Date & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date:', style: TextStyle(color: Colors.grey[600])),
                Text(formattedDate, style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time:', style: TextStyle(color: Colors.grey[600])),
                Text(formattedTime, style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Location:', style: TextStyle(color: Colors.grey[600])),
                Expanded(
                  child: Text(
                    _location,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Photo Preview
            if (_capturedImage != null || _galleryImage != null)
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File((_capturedImage?.path ?? _galleryImage?.path)!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            SizedBox(height: 30),
            
            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'MARK AGAIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'BACK TO DASHBOARD',
                style: TextStyle(color: GlobalColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';

// class EmployeeAttendancePage extends StatelessWidget {
//   const EmployeeAttendancePage({super.key, required List cameras});

//   Future<void> _markAttendance(BuildContext context) async {
//     final attendance = context.read<AttendanceProvider>();
//     final employee = context.read<EmployeeProvider>().profile;

//     // 📸 Take selfie
//     final picker = ImagePicker();
//     final photo = await picker.pickImage(source: ImageSource.camera);
//     if (photo == null) return;

//     // 📍 Get location
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     final location =
//         "Lat ${position.latitude}, Lng ${position.longitude}";

//     await attendance.markAttendance(
//       employeeName: employee?['full_name'] ?? 'Employee',
//       selfieUrl: photo.path, // later upload to storage
//       locationText: location,
//     );

//     // 🎉 Success popup
//     showDialog(
//       context: context,
//       builder: (_) => _AttendanceSuccessCard(
//         name: employee?['full_name'] ?? '',
//         time: attendance.checkInTime ?? '',
//         location: attendance.location ?? '',
//         image: photo.path,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attendance = context.watch<AttendanceProvider>();

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         title: const Text("Mark Attendance"),
//         backgroundColor: GlobalColors.primaryBlue,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.fingerprint,
//                 size: 80, color: GlobalColors.primaryBlue),
//             const SizedBox(height: 20),
//             const Text(
//               "Verify Your Presence",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               "Take a selfie to mark your attendance",
//               style: TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.camera_alt),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GlobalColors.primaryBlue,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//               onPressed: attendance.attendanceMarkedToday || attendance.loading
//                   ? null
//                   : () => _markAttendance(context),
//               label: Text(
//                 attendance.attendanceMarkedToday
//                     ? "Already Marked"
//                     : "Mark Attendance",
//                 style: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// class _AttendanceSuccessCard extends StatelessWidget {
//   final String name, time, location, image;

//   const _AttendanceSuccessCard({
//     required this.name,
//     required this.time,
//     required this.location,
//     required this.image,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle,
//                 size: 70, color: Colors.green),
//             const SizedBox(height: 12),
//             Text(name,
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             Text("Time: $time"),
//             Text("Location: $location"),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Done"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }













// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mega_pro/global/global_variables.dart';

// class EmployeeAttendancePage extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   const EmployeeAttendancePage({super.key, required this.cameras});

//   @override
//   State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
// }

// class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
//   CameraController? _controller;
//   XFile? _capturedImage;
//   final _nameController = TextEditingController(text: "John Doe");
//   final _idController = TextEditingController(text: "CF-8821");

//   @override
//   void initState() {
//     super.initState();
//     if (widget.cameras.isNotEmpty) {
//       _controller =
//           CameraController(widget.cameras[0], ResolutionPreset.medium);
//       _controller!.initialize().then((_) {
//         if (!mounted) return;
//         setState(() {});
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _nameController.dispose();
//     _idController.dispose();
//     super.dispose();
//   }

//   Future<void> captureImage() async {
//     if (_controller != null && _controller!.value.isInitialized) {
//       final XFile image = await _controller!.takePicture();
//       setState(() => _capturedImage = image);
//     }
//   }

//   Future<void> pickFromGallery() async {
//     final XFile? image =
//         await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       setState(() => _capturedImage = image);
//     }
//   }

//   void switchCamera() {
//     if (widget.cameras.length > 1) {
//       final newIndex =
//           (_controller!.description == widget.cameras[0] ? 1 : 0);
//       _controller =
//           CameraController(widget.cameras[newIndex], ResolutionPreset.medium);
//       _controller!.initialize().then((_) {
//         if (!mounted) return;
//         setState(() {});
//       });
//     }
//   }

//   void _submitAttendance() {
//     if (_nameController.text.isEmpty || _idController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please fill Employee Name and ID!"),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//       return;
//     }
//     if (_capturedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please capture selfie first!"),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//       return;
//     }

//     // Show success dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: GlobalColors.success.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.check_circle,
//                   color: GlobalColors.success,
//                   size: 50,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Attendance Submitted!",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1E293B),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 "Time: ${TimeOfDay.now().format(context)}",
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: AppColors.secondaryText,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context); // Close dialog
//                     Navigator.pop(context); // Go back
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text(
//                     "Done",
//                     style: TextStyle(
//                       color: GlobalColors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         //centerTitle: true,
//         title: const Text(
//           "Mark Attendance",
//           style: TextStyle(
//             color: GlobalColors.white,
//             fontWeight: FontWeight.w800,
//             fontSize: 20,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Header Section
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//             ),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
               
//                 Text(
//                   "Capture your photo to mark attendance",
//                   style: TextStyle(
//                     color: GlobalColors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Camera Preview Section
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.shadowGrey.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         const Text(
//                           "Capture Selfie",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1E293B),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           "Ensure your face is clearly visible",
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: AppColors.secondaryText,
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Camera Preview
//                         Container(
//                           width: double.infinity,
//                           height: MediaQuery.of(context).size.width * 0.7,
//                           decoration: BoxDecoration(
//                             color: AppColors.softGreyBg,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(
//                               color: AppColors.borderGrey,
//                               width: 1,
//                             ),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: _capturedImage != null
//                                 ? Image.file(
//                                     File(_capturedImage!.path),
//                                     fit: BoxFit.cover,
//                                   )
//                                 : (_controller != null &&
//                                         _controller!.value.isInitialized
//                                     ? CameraPreview(_controller!)
//                                     : const Center(
//                                         child: CircularProgressIndicator(
//                                           color: GlobalColors.primaryBlue,
//                                         ),
//                                       )),
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         // Camera Controls
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             // Gallery Button
//                             Container(
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: AppColors.softGreyBg,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: IconButton(
//                                 onPressed: pickFromGallery,
//                                 icon: Icon(
//                                   Icons.photo_library,
//                                   color: GlobalColors.primaryBlue,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 24),

//                             // Capture Button
//                             Container(
//                               width: 70,
//                               height: 70,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: GlobalColors.primaryBlue,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: GlobalColors.primaryBlue.withOpacity(0.3),
//                                     blurRadius: 10,
//                                     spreadRadius: 2,
//                                   ),
//                                 ],
//                               ),
//                               child: IconButton(
//                                 onPressed: captureImage,
//                                 icon: const Icon(
//                                   Icons.camera_alt,
//                                   color: GlobalColors.white,
//                                   size: 30,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 24),

//                             // Switch Camera Button
//                             Container(
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: AppColors.softGreyBg,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: IconButton(
//                                 onPressed: switchCamera,
//                                 icon: Icon(
//                                   Icons.cameraswitch,
//                                   color: GlobalColors.primaryBlue,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Status Cards
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildStatusCard(
//                           icon: Icons.schedule,
//                           title: "Time",
//                           value: TimeOfDay.now().format(context),
//                           subtitle: "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildStatusCard(
//                           icon: Icons.location_on,
//                           title: "Location",
//                           value: "Farm Location",
//                           subtitle: "GPS Active",
//                           color: GlobalColors.success,
//                           isStatus: true,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   // Employee Details
//                   const Text(
//                     "Employee Details",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Name Field
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: AppColors.borderGrey),
//                     ),
//                     child: TextFormField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         border: InputBorder.none,
//                         labelText: "Employee Name",
//                         labelStyle: TextStyle(
//                           color: AppColors.secondaryText,
//                           fontSize: 14,
//                         ),
//                         prefixIcon: Icon(
//                           Icons.person_outline,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 15,
//                         color: Color(0xFF1E293B),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // ID Field
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: GlobalColors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: AppColors.borderGrey),
//                     ),
//                     child: TextFormField(
//                       controller: _idController,
//                       decoration: InputDecoration(
//                         border: InputBorder.none,
//                         labelText: "Employee ID",
//                         labelStyle: TextStyle(
//                           color: AppColors.secondaryText,
//                           fontSize: 14,
//                         ),
//                         prefixIcon: Icon(
//                           Icons.badge_outlined,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 15,
//                         color: Color(0xFF1E293B),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),

//           // Submit Button
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: GlobalColors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _submitAttendance,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 18),
//                 ),
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.check_circle_outline, color: GlobalColors.white),
//                     SizedBox(width: 12),
//                     Text(
//                       "SUBMIT ATTENDANCE",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: GlobalColors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard({
//     required IconData icon,
//     required String title,
//     required String value,
//     required String subtitle,
//     required Color color,
//     bool isStatus = false,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: GlobalColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowGrey.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.secondaryText,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF1E293B),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               if (isStatus)
//                 Container(
//                   width: 8,
//                   height: 8,
//                   margin: const EdgeInsets.only(right: 6),
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.secondaryText,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }