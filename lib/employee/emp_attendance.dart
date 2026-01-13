import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:provider/provider.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key, required List cameras});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  XFile? _capturedImage;
  String _location = 'Fetching location...';
  File? _galleryImage;
  bool _showConfirmation = false;
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;

  @override
  void initState() {
    super.initState();
    // Start checking location on init
    _checkAndGetLocation();
  }

  // NEW: Main function to handle location
  Future<void> _checkAndGetLocation() async {
    setState(() {
      _isGettingLocation = true;
      _location = 'Checking location...';
    });

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        setState(() {
          _serviceDisabled = true;
          _location = 'Location services are disabled';
        });
        return;
      }

      // 2. Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission if not granted
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _permissionDenied = true;
            _location = 'Location permission denied';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _location = 'Location permission permanently denied. Please enable in Settings';
        });
        return;
      }

      // 3. Permission granted, get location
      _permissionDenied = false;
      _serviceDisabled = false;
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      _currentPosition = position;
      
      setState(() {
        _location = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
      
    } catch (e) {
      debugPrint('Location error: $e');
      
      // Try fallback to last known location
      _tryGetLastKnownLocation();
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  // Fallback: Get last known location
  Future<void> _tryGetLastKnownLocation() async {
    try {
      final Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _currentPosition = lastPosition;
        setState(() {
          _location = 'Last known: ${lastPosition.latitude.toStringAsFixed(6)}, ${lastPosition.longitude.toStringAsFixed(6)}';
        });
      } else {
        setState(() {
          _location = 'Unable to fetch location';
        });
      }
    } catch (e) {
      debugPrint('Last known location error: $e');
      setState(() {
        _location = 'Location unavailable';
      });
    }
  }

  // Function to retry getting location
  Future<void> _retryLocation() async {
    await _checkAndGetLocation();
  }

  // Helper function to check location accuracy
  bool _isLocationAccurate() {
    if (_currentPosition == null) return false;
    
    // Check if location is recent (within last 30 seconds)
    final locationAge = DateTime.now().difference(_currentPosition!.timestamp);
    if (locationAge.inSeconds > 30) {
      return false;
    }
    
    // Check accuracy (in meters)
    if (_currentPosition!.accuracy > 100) {
      return false;
    }
    
    return true;
  }

  // KEEP ALL YOUR CAMERA FUNCTIONS EXACTLY AS THEY ARE
  Future<void> _takePhotoWithCamera() async {
    setState(() => _isCapturing = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _galleryImage = null;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: GlobalColors.danger,
        ),
      );
    } finally {
      setState(() => _isCapturing = false);
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
    // Refresh location when marking again
    _checkAndGetLocation();
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
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                
                // KEEP CAMERA BUTTONS EXACTLY AS THEY ARE
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCapturing ? null : _takePhotoWithCamera,
                        icon: Icon(_isCapturing ? Icons.camera : Icons.camera_alt),
                        label: Text(_isCapturing ? 'Capturing...' : 'Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCapturing ? Colors.grey : GlobalColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // KEEP IMAGE PREVIEW EXACTLY AS IT IS
                if (_isCapturing)
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
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Opening camera...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else if (_capturedImage != null || _galleryImage != null)
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File((_capturedImage?.path ?? _galleryImage?.path)!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FloatingActionButton.small(
                            onPressed: () {
                              setState(() {
                                _capturedImage = null;
                                _galleryImage = null;
                              });
                            },
                            backgroundColor: GlobalColors.danger,
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
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
                        const SizedBox(height: 12),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap Gallery or Camera to add a photo',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // UPDATED LOCATION WIDGET
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on, 
                            color: _permissionDenied || _serviceDisabled 
                                ? Colors.red 
                                : _isLocationAccurate() 
                                  ? GlobalColors.success 
                                  : GlobalColors.warning
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Current Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_isGettingLocation) ...[
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: GlobalColors.primaryBlue,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _permissionDenied || _serviceDisabled 
                                        ? Colors.red 
                                        : _isLocationAccurate() 
                                          ? Colors.green 
                                          : Colors.orange,
                                  ),
                                ),
                                if (_currentPosition != null && !_isGettingLocation) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Action buttons for location issues
                      if (_permissionDenied || _serviceDisabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _retryLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlobalColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  _permissionDenied ? 'Request Permission' : 'Enable Location',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () async {
                                if (_serviceDisabled) {
                                  await Geolocator.openLocationSettings();
                                } else if (_permissionDenied) {
                                  await Geolocator.openAppSettings();
                                }
                              },
                              color: GlobalColors.primaryBlue,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Location status warning
                if ((_permissionDenied || _serviceDisabled) && !_isGettingLocation)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red[800]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serviceDisabled 
                                ? 'Location services are disabled. Please enable them.'
                                : 'Location permission is required to record your attendance location.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[800],
                            ),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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

  // KEEP ALL OTHER WIDGETS EXACTLY AS THEY ARE
  Widget _buildAttendanceForm() {
    final employeeProvider = context.watch<EmployeeProvider>();
    final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
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
        
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, color: GlobalColors.primaryBlue),
                    const SizedBox(height: 8),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.access_time, color: GlobalColors.primaryBlue),
                    const SizedBox(height: 8),
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
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
            const SizedBox(height: 16),
            Text(
              'Attendance Marked Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GlobalColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date:', style: TextStyle(color: Colors.grey[600])),
                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time:', style: TextStyle(color: Colors.grey[600])),
                Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Location:', style: TextStyle(color: Colors.grey[600])),
                Expanded(
                  child: Text(
                    _location,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _permissionDenied || _serviceDisabled 
                          ? Colors.red 
                          : _isLocationAccurate() 
                            ? Colors.green 
                            : Colors.orange,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (_currentPosition != null && !_isGettingLocation) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Accuracy:', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            
            if (_capturedImage != null || _galleryImage != null)
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File((_capturedImage?.path ?? _galleryImage?.path)!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'MARK AGAIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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




//camera works location does not


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeAttendancePage extends StatefulWidget {
//   const EmployeeAttendancePage({super.key, required List cameras});

//   @override
//   State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
// }

// class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
//   XFile? _capturedImage;
//   String _location = 'Fetching location...';
//   File? _galleryImage;
//   bool _showConfirmation = false;
//   final ImagePicker _picker = ImagePicker();
//   bool _isCapturing = false;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void _getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => _location = 'Location service disabled');
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission != LocationPermission.whileInUse && 
//             permission != LocationPermission.always) {
//           setState(() => _location = 'Location permission denied');
//           return;
//         }
//       }

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       );
//       setState(() {
//         _location = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
//       });
//     } catch (e) {
//       debugPrint('Location error: $e');
//       setState(() => _location = 'Unable to fetch location');
//     }
//   }

//   Future<void> _takePhotoWithCamera() async {
//     setState(() => _isCapturing = true);
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 85,
//       );
      
//       if (image != null) {
//         setState(() {
//           _capturedImage = image;
//           _galleryImage = null;
//         });
//       }
//     } catch (e) {
//       debugPrint('Camera error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to take photo: $e'),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//     } finally {
//       setState(() => _isCapturing = false);
//     }
//   }

//   Future<void> _pickImageFromGallery() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//       );
      
//       if (image != null) {
//         setState(() {
//           _galleryImage = File(image.path);
//           _capturedImage = null;
//         });
//       }
//     } catch (e) {
//       debugPrint('Gallery error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to pick image: $e'),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//     }
//   }

//   Future<void> _submitAttendance() async {
//   final attendanceProvider = context.read<AttendanceProvider>();
//   final employeeProvider = context.read<EmployeeProvider>();
//   final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
  
//   final imageFile = _galleryImage ?? (_capturedImage != null ? File(_capturedImage!.path) : null);
  
//   if (imageFile == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Please take or select a photo'),
//         backgroundColor: GlobalColors.danger,
//       ),
//     );
//     return;
//   }

//   try {
//     final fakeImageUrl = 'attendance_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
//     await attendanceProvider.markAttendance(
//       employeeName: empName,
//       selfieUrl: fakeImageUrl,
//       locationText: _location,
//     );
    
//     setState(() => _showConfirmation = true);
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to mark attendance: ${e.toString()}'),
//         backgroundColor: GlobalColors.danger,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }
// }

//   void _resetAttendance() {
//     setState(() {
//       _capturedImage = null;
//       _galleryImage = null;
//       _showConfirmation = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attendanceProvider = context.watch<AttendanceProvider>();
//     final now = DateTime.now();

//     if (attendanceProvider.loading) {
//       return Scaffold(
//         backgroundColor: AppColors.scaffoldBg,
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: const Text(
//           'Mark Attendance',
//           style: TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (_showConfirmation) _buildConfirmationCard(now) else _buildAttendanceForm(),
              
//               if (!_showConfirmation) ...[
//                 const SizedBox(height: 20),
//                 Text(
//                   'Select or Capture Selfie',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _pickImageFromGallery,
//                         icon: const Icon(Icons.photo_library),
//                         label: const Text('Gallery'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: GlobalColors.primaryBlue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isCapturing ? null : _takePhotoWithCamera,
//                         icon: Icon(_isCapturing ? Icons.camera : Icons.camera_alt),
//                         label: Text(_isCapturing ? 'Capturing...' : 'Camera'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _isCapturing ? Colors.grey : GlobalColors.primaryBlue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 if (_isCapturing)
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 20),
//                         Text(
//                           'Opening camera...',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                   )
//                 else if (_capturedImage != null || _galleryImage != null)
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: Image.file(
//                             File((_capturedImage?.path ?? _galleryImage?.path)!),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: FloatingActionButton.small(
//                             onPressed: () {
//                               setState(() {
//                                 _capturedImage = null;
//                                 _galleryImage = null;
//                               });
//                             },
//                             backgroundColor: GlobalColors.danger,
//                             child: const Icon(Icons.close, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 else
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.camera_alt, size: 60, color: Colors.grey[400]),
//                         const SizedBox(height: 12),
//                         Text(
//                           'No image selected',
//                           style: TextStyle(color: Colors.grey[500]),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Tap Gallery or Camera to add a photo',
//                           style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
                
//                 const SizedBox(height: 20),
                
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.location_on, color: GlobalColors.primaryBlue),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Current Location',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _location,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: _getCurrentLocation,
//                         color: GlobalColors.primaryBlue,
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const SizedBox(height: 30),
                
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitAttendance,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'MARK ATTENDANCE',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceForm() {
//     final employeeProvider = context.watch<EmployeeProvider>();
//     final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
//     final now = DateTime.now();
//     final formattedDate = '${now.day}/${now.month}/${now.year}';
//     final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: GlobalColors.primaryBlue,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.white,
//                 child: Icon(Icons.person, color: GlobalColors.primaryBlue),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       empName,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       employeeProvider.profile?['position'] ?? 'Employee',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         const SizedBox(height: 20),
        
//         Row(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.calendar_today, color: GlobalColors.primaryBlue),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Date',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       formattedDate,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.access_time, color: GlobalColors.primaryBlue),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Time',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       formattedTime,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildConfirmationCard(DateTime timestamp) {
//     final now = timestamp;
//     final formattedDate = '${now.day}/${now.month}/${now.year}';
//     final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.check_circle,
//               size: 80,
//               color: GlobalColors.success,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Attendance Marked Successfully!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: GlobalColors.primaryBlue,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
            
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Date:', style: TextStyle(color: Colors.grey[600])),
//                 Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Time:', style: TextStyle(color: Colors.grey[600])),
//                 Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Location:', style: TextStyle(color: Colors.grey[600])),
//                 Expanded(
//                   child: Text(
//                     _location,
//                     textAlign: TextAlign.right,
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                     maxLines: 2,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             if (_capturedImage != null || _galleryImage != null)
//               Container(
//                 height: 150,
//                 width: 150,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(
//                     File((_capturedImage?.path ?? _galleryImage?.path)!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
            
//             const SizedBox(height: 30),
            
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _resetAttendance,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'MARK AGAIN',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 12),
            
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text(
//                 'BACK TO DASHBOARD',
//                 style: TextStyle(color: GlobalColors.primaryBlue),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:camera/camera.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/providers/emp_attendance_provider.dart';
// import 'package:mega_pro/providers/emp_provider.dart';
// import 'package:provider/provider.dart';

// class EmployeeAttendancePage extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   const EmployeeAttendancePage({super.key, required this.cameras});

//   @override
//   State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
// }

// class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
//   CameraController? _cameraController;
//   bool _isCameraReady = false;
//   bool _isCapturing = false;
//   XFile? _capturedImage;
//   String _location = 'Fetching location...';
//   File? _galleryImage;
//   bool _showConfirmation = false;
//   bool _showCameraView = false; // New flag to control camera view
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     // Don't initialize camera automatically - wait for user to click camera button
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   void _initializeCamera() async {
//     try {
//       if (widget.cameras.isEmpty) {
//         setState(() {
//           _isCameraReady = false;
//           _showCameraView = false;
//         });
        
//         // If no camera available, ask for gallery image
//         await _pickImageFromGallery();
//         return;
//       }

//       // Use front camera if available, otherwise use first camera
//       CameraDescription? selectedCamera;
//       for (var camera in widget.cameras) {
//         if (camera.lensDirection == CameraLensDirection.front) {
//           selectedCamera = camera;
//           break;
//         }
//       }
//       selectedCamera ??= widget.cameras.first;

//       _cameraController = CameraController(
//         selectedCamera,
//         ResolutionPreset.medium,
//       );
      
//       await _cameraController!.initialize();
      
//       setState(() {
//         _isCameraReady = true;
//         _showCameraView = true; // Show camera view
//       });
//     } catch (e) {
//       debugPrint('Camera initialization error: $e');
//       setState(() {
//         _isCameraReady = false;
//         _showCameraView = false;
//       });
      
//       // If camera fails, ask for gallery image
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Camera not available. Please select from gallery.'),
//           backgroundColor: GlobalColors.warning,
//         ),
//       );
//       await _pickImageFromGallery();
//     }
//   }

//   void _closeCamera() {
//     _cameraController?.dispose();
//     _cameraController = null;
//     setState(() {
//       _isCameraReady = false;
//       _showCameraView = false;
//     });
//   }

//   void _getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() => _location = 'Location service disabled');
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission != LocationPermission.whileInUse && 
//             permission != LocationPermission.always) {
//           setState(() => _location = 'Location permission denied');
//           return;
//         }
//       }

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       );
//       setState(() {
//         _location = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
//       });
//     } catch (e) {
//       debugPrint('Location error: $e');
//       setState(() => _location = 'Unable to fetch location');
//     }
//   }

//   Future<void> _captureImage() async {
//     if (_isCameraReady && !_isCapturing) {
//       setState(() => _isCapturing = true);
//       try {
//         final image = await _cameraController!.takePicture();
//         setState(() {
//           _capturedImage = image;
//           _galleryImage = null;
//         });
//         _closeCamera(); // Close camera after capturing
//       } catch (e) {
//         debugPrint('Capture error: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to capture image: $e'),
//             backgroundColor: GlobalColors.danger,
//           ),
//         );
//       } finally {
//         setState(() => _isCapturing = false);
//       }
//     }
//   }

//   Future<void> _pickImageFromGallery() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//       );
      
//       if (image != null) {
//         setState(() {
//           _galleryImage = File(image.path);
//           _capturedImage = null;
//           _showCameraView = false; // Hide camera if gallery image is selected
//         });
//       }
//     } catch (e) {
//       debugPrint('Gallery error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to pick image: $e'),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//     }
//   }

//   Future<void> _submitAttendance() async {
//   final attendanceProvider = context.read<AttendanceProvider>();
//   final employeeProvider = context.read<EmployeeProvider>();
//   final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
  
//   final imageFile = _galleryImage ?? (_capturedImage != null ? File(_capturedImage!.path) : null);
  
//   if (imageFile == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Please take or select a photo'),
//         backgroundColor: GlobalColors.danger,
//       ),
//     );
//     return;
//   }

//   try {
//     // Upload image to Supabase Storage (if you have storage setup)
//     // For now, we'll use a placeholder or save locally
//     final fakeImageUrl = 'attendance_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
//     await attendanceProvider.markAttendance(
//       employeeName: empName,
//       selfieUrl: fakeImageUrl,
//       locationText: _location,
//     );
    
//     setState(() => _showConfirmation = true);
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to mark attendance: ${e.toString()}'),
//         backgroundColor: GlobalColors.danger,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }
// }

//   void _resetAttendance() {
//     setState(() {
//       _capturedImage = null;
//       _galleryImage = null;
//       _showConfirmation = false;
//       _showCameraView = false;
//     });
//     _closeCamera();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attendanceProvider = context.watch<AttendanceProvider>();
//     final now = DateTime.now();

//     if (attendanceProvider.loading) {
//       return Scaffold(
//         backgroundColor: AppColors.scaffoldBg,
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: const Text(
//           'Mark Attendance',
//           style: TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             _closeCamera();
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (_showConfirmation) _buildConfirmationCard(now) else _buildAttendanceForm(),
              
//               if (!_showConfirmation) ...[
//                 const SizedBox(height: 20),
//                 Text(
//                   'Select or Capture Selfie',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 // Image picker options
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _pickImageFromGallery,
//                         icon: const Icon(Icons.photo_library),
//                         label: const Text('Gallery'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: GlobalColors.primaryBlue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () async {
//                           if (_showCameraView) {
//                             // If camera is already open, capture image
//                             await _captureImage();
//                           } else {
//                             // If camera is not open, initialize and show it
//                             _initializeCamera();
//                           }
//                         },
//                         icon: Icon(_showCameraView ? Icons.camera : Icons.camera_alt),
//                         label: Text(_showCameraView ? 'Capture' : 'Camera'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _showCameraView ? GlobalColors.success : GlobalColors.primaryBlue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Camera Preview (only shown when _showCameraView is true)
//                 if (_showCameraView && _isCameraReady)
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Stack(
//                       children: [
//                         CameraPreview(_cameraController!),
//                         Positioned(
//                           bottom: 16,
//                           left: 0,
//                           right: 0,
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               FloatingActionButton(
//                                 onPressed: () {
//                                   _closeCamera();
//                                   setState(() {
//                                     _showCameraView = false;
//                                   });
//                                 },
//                                 backgroundColor: GlobalColors.danger,
//                                 child: const Icon(Icons.close, color: Colors.white),
//                               ),
//                               const SizedBox(width: 20),
//                               FloatingActionButton(
//                                 onPressed: _captureImage,
//                                 backgroundColor: GlobalColors.primaryBlue,
//                                 child: _isCapturing
//                                     ? const CircularProgressIndicator(color: Colors.white)
//                                     : const Icon(Icons.camera, color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 // Show captured image or gallery image
//                 else if (_capturedImage != null || _galleryImage != null)
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: Image.file(
//                             File((_capturedImage?.path ?? _galleryImage?.path)!),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: FloatingActionButton.small(
//                             onPressed: () {
//                               setState(() {
//                                 _capturedImage = null;
//                                 _galleryImage = null;
//                               });
//                             },
//                             backgroundColor: GlobalColors.danger,
//                             child: const Icon(Icons.close, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 // Show placeholder when no image is selected
//                 else
//                   Container(
//                     height: 300,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.camera_alt, size: 60, color: Colors.grey[400]),
//                         const SizedBox(height: 12),
//                         Text(
//                           'No image selected',
//                           style: TextStyle(color: Colors.grey[500]),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Tap Gallery or Camera to add a photo',
//                           style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
                
//                 const SizedBox(height: 20),
                
//                 // Current Location
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.location_on, color: GlobalColors.primaryBlue),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Current Location',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _location,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: _getCurrentLocation,
//                         color: GlobalColors.primaryBlue,
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const SizedBox(height: 30),
                
//                 // Submit Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submitAttendance,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'MARK ATTENDANCE',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceForm() {
//     final employeeProvider = context.watch<EmployeeProvider>();
//     final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
//     final now = DateTime.now();
//     final formattedDate = '${now.day}/${now.month}/${now.year}';
//     final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Employee Info Card
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: GlobalColors.primaryBlue,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.white,
//                 child: Icon(Icons.person, color: GlobalColors.primaryBlue),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       empName,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       employeeProvider.profile?['position'] ?? 'Employee',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         const SizedBox(height: 20),
        
//         // Date & Time Info
//         Row(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.calendar_today, color: GlobalColors.primaryBlue),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Date',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       formattedDate,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.access_time, color: GlobalColors.primaryBlue),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Time',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       formattedTime,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildConfirmationCard(DateTime timestamp) {
//     final now = timestamp;
//     final formattedDate = '${now.day}/${now.month}/${now.year}';
//     final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.check_circle,
//               size: 80,
//               color: GlobalColors.success,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Attendance Marked Successfully!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: GlobalColors.primaryBlue,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
            
//             // Date & Time
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Date:', style: TextStyle(color: Colors.grey[600])),
//                 Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Time:', style: TextStyle(color: Colors.grey[600])),
//                 Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Location:', style: TextStyle(color: Colors.grey[600])),
//                 Expanded(
//                   child: Text(
//                     _location,
//                     textAlign: TextAlign.right,
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                     maxLines: 2,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Photo Preview
//             if (_capturedImage != null || _galleryImage != null)
//               Container(
//                 height: 150,
//                 width: 150,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(
//                     File((_capturedImage?.path ?? _galleryImage?.path)!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
            
//             const SizedBox(height: 30),
            
//             // Reset Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _resetAttendance,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'MARK AGAIN',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 12),
            
//             TextButton(
//               onPressed: () {
//                 _closeCamera();
//                 Navigator.pop(context);
//               },
//               child: Text(
//                 'BACK TO DASHBOARD',
//                 style: TextStyle(color: GlobalColors.primaryBlue),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




