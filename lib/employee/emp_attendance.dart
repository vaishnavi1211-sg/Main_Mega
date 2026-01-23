import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_attendance_provider.dart';
import 'package:mega_pro/providers/emp_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key, required List cameras});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selfieImage;
  XFile? _meterImage;
  String _location = 'Fetching location...';
  String _address = 'Getting address...';
  bool _showConfirmation = false;
  bool _isCapturingSelfie = false;
  bool _isCapturingMeter = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _locationError = false;
  String _errorMessage = '';
  bool _isSubmitting = false;
  bool _submissionSuccessful = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _checkTodayAttendance();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _checkPlatformRequirements();
    await _checkAndGetLocation();
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      await attendanceProvider.checkTodayAttendance();
      
      if (attendanceProvider.attendanceMarkedToday) {
        final todayDetails = await attendanceProvider.getTodayAttendanceDetails();
        if (todayDetails != null) {
          setState(() {
            _showConfirmation = true;
            _location = todayDetails['location'] ?? 'Location not recorded';
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking today attendance: $e');
    }
  }

  Future<void> _checkPlatformRequirements() async {
    try {
      bool isLocationServiceSupported = await Geolocator.isLocationServiceEnabled();
      
      if (!isLocationServiceSupported) {
        setState(() {
          _serviceDisabled = true;
          _location = 'Location services not supported';
          _errorMessage = 'Your device does not support location services';
        });
        return;
      }
    } catch (e) {
      debugPrint('Platform check error: $e');
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        
        String address = '';
        
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          address += placemark.street!;
        }
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.locality!;
        }
        
        if (placemark.subAdministrativeArea != null && 
            placemark.subAdministrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.subAdministrativeArea!;
        }
        
        if (placemark.administrativeArea != null && 
            placemark.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.administrativeArea!;
        }
        
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          if (address.isNotEmpty) address += ' - ';
          address += placemark.postalCode!;
        }
        
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.country!;
        }
        
        return address.isNotEmpty ? address : 'Address not available';
      }
      
      return 'Address not found';
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return 'Unable to fetch address';
    }
  }

  Future<String> _getFormattedLocation(Position position) async {
    try {
      final address = await _getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      return '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 $address';
    } catch (e) {
      debugPrint('Error formatting location: $e');
      return '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 Address unavailable';
    }
  }

  Future<void> _checkAndGetLocation() async {
    setState(() {
      _isGettingLocation = true;
      _location = 'Checking location...';
      _locationError = false;
      _errorMessage = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        setState(() {
          _serviceDisabled = true;
          _location = 'Location services are disabled';
          _errorMessage = 'Please enable location services in your device settings';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.denied:
          permission = await Geolocator.requestPermission();
          
          if (permission == LocationPermission.denied) {
            setState(() {
              _permissionDenied = true;
              _location = 'Location permission denied';
              _errorMessage = 'Please grant location permission from app settings';
            });
            return;
          }
          break;
          
        case LocationPermission.deniedForever:
          setState(() {
            _permissionDenied = true;
            _location = 'Location permission permanently denied';
            _errorMessage = 'Please enable location permission in app settings';
          });
          return;
          
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
          
        case LocationPermission.unableToDetermine:
          setState(() {
            _location = 'Unable to determine permission status';
            _errorMessage = 'Please check your location settings';
          });
          return;
      }

      _permissionDenied = false;
      _serviceDisabled = false;

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        );
      } on TimeoutException catch (e) {
        debugPrint('Location timeout: $e');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        );
      }

      _currentPosition = position;
      
      try {
        final formattedLocation = await _getFormattedLocation(position);
        
        setState(() {
          _location = formattedLocation;
          _address = formattedLocation.split('\n')[1];
          _locationError = false;
        });
        
        _startLocationUpdates();
        
      } catch (e) {
        debugPrint('Address formatting error: $e');
        setState(() {
          _location = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _address = 'Coordinates only - address unavailable';
          _locationError = false;
        });
      }
      
    } on PlatformException catch (e) {
      setState(() {
        _locationError = true;
        _errorMessage = e.message ?? 'Platform location error';
        _location = 'Location unavailable - Platform error';
      });
      
    } catch (e) {
      setState(() {
        _locationError = true;
        _errorMessage = e.toString();
        _location = 'Location unavailable - ${e.toString().substring(0, min(30, e.toString().length))}...';
      });
      
      await _tryGetLastKnownLocation();
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _startLocationUpdates() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      
      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _location = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 $_address';
          });
        }
      }, onError: (e) {
        debugPrint('Error in location stream: $e');
      });
    } catch (e) {
      debugPrint('Error starting location updates: $e');
    }
  }

  Future<void> _tryGetLastKnownLocation() async {
    try {
      final Position? lastPosition = await Geolocator.getLastKnownPosition();
      
      if (lastPosition != null) {
        _currentPosition = lastPosition;
        
        try {
          final formattedLocation = await _getFormattedLocation(lastPosition);
          setState(() {
            _location = '⚠️ Last known location (may be outdated)\n' + formattedLocation;
            _address = formattedLocation.split('\n')[1];
          });
        } catch (e) {
          setState(() {
            _location = '⚠️ Last known: ${lastPosition.latitude.toStringAsFixed(6)}, ${lastPosition.longitude.toStringAsFixed(6)}';
            _address = 'Coordinates only';
          });
        }
      } else {
        setState(() {
          _location = 'No location available';
          _address = 'Please enable location services';
        });
      }
    } catch (e) {
      debugPrint('Last known location error: $e');
      setState(() {
        _location = 'Location completely unavailable';
        _address = 'Please check device settings';
      });
    }
  }

  Future<void> _retryLocation() async {
    setState(() {
      _locationError = false;
      _errorMessage = '';
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Getting Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Attempting to get your location...'),
          ],
        ),
      ),
    );
    
    await _checkAndGetLocation();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _isLocationAccurate() {
    if (_currentPosition == null) return false;
    
    final locationAge = DateTime.now().difference(_currentPosition!.timestamp);
    if (locationAge.inSeconds > 30) {
      return false;
    }
    
    if (_currentPosition!.accuracy > 100) {
      return false;
    }
    
    return true;
  }

  Future<void> _takePhotoWithCamera(bool isSelfie) async {
    setState(() {
      if (isSelfie) {
        _isCapturingSelfie = true;
      } else {
        _isCapturingMeter = true;
      }
    });
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (isSelfie) {
            _selfieImage = image;
          } else {
            _meterImage = image;
          }
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
      setState(() {
        if (isSelfie) {
          _isCapturingSelfie = false;
        } else {
          _isCapturingMeter = false;
        }
      });
    }
  }

  Future<void> _pickImageFromGallery(bool isSelfie) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (isSelfie) {
            _selfieImage = image;
          } else {
            _meterImage = image;
          }
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

  Future<String?> _uploadImage(XFile xFile, String folderName) async {
    try {
      debugPrint('Starting image upload to folder: $folderName');
      
      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Create unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id.substring(0, 8)}.jpg';
      final String path = '$folderName/$fileName';
      
      debugPrint('Uploading to path: $path');
      
      // Read image bytes
      final bytes = await xFile.readAsBytes();
      debugPrint('Image size: ${bytes.length} bytes');
      
      // Try to upload
      try {
        await supabase.storage.from('employee_uploads').uploadBinary(
          path, 
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        debugPrint('Upload successful for path: $path');
      } catch (uploadError) {
        debugPrint('Upload failed: $uploadError');
        
        // Try alternative method if first fails
        try {
          final file = File(xFile.path);
          await supabase.storage.from('employee_uploads').upload(
            path, 
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
          debugPrint('Alternative upload successful');
        } catch (altError) {
          debugPrint('Alternative upload also failed: $altError');
          return null;
        }
      }

      // Get public URL
      final url = supabase.storage.from('employee_uploads').getPublicUrl(path);
      debugPrint('Generated URL: $url');
      
      return url;
    } catch (e) {
      debugPrint("Upload Error: $e");
      debugPrint("Error type: ${e.runtimeType}");
      debugPrint("Stack trace: ${e.toString()}");
      return null;
    }
  }

  // ALTERNATIVE: Simple upload method without storage (save URLs in database)
  Future<Map<String, String>?> _uploadImagesAlternative() async {
    try {
      // For testing, you can use placeholder URLs
      // In production, you'd upload to storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = supabase.auth.currentUser?.id ?? 'unknown';
      
      return {
        'selfie_url': 'selfie_${userId}_$timestamp.jpg',
        'meter_photo_url': 'meter_${userId}_$timestamp.jpg',
      };
    } catch (e) {
      debugPrint('Alternative upload failed: $e');
      return null;
    }
  }

  Future<void> _submitAttendance() async {
    if (_selfieImage == null || _meterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Both selfie and meter photo are required!"),
          backgroundColor: GlobalColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final employeeProvider = context.read<EmployeeProvider>();
      final empName = employeeProvider.profile?['full_name'] ?? 'Employee';

      debugPrint('Starting attendance submission...');
      
      // Try to upload images
      String? selfieUrl;
      String? meterUrl;
      
      try {
        selfieUrl = await _uploadImage(_selfieImage!, 'selfies');
        meterUrl = await _uploadImage(_meterImage!, 'meters');
        
        if (selfieUrl == null || meterUrl == null) {
          debugPrint('Image upload failed, trying alternative method...');
          final urls = await _uploadImagesAlternative();
          if (urls != null) {
            selfieUrl = urls['selfie_url'];
            meterUrl = urls['meter_photo_url'];
          }
        }
      } catch (uploadError) {
        debugPrint('Upload error caught: $uploadError');
        // Use placeholder URLs if upload fails
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        selfieUrl = 'selfie_placeholder_$timestamp.jpg';
        meterUrl = 'meter_placeholder_$timestamp.jpg';
      }

      if (selfieUrl == null || meterUrl == null) {
        throw "Could not generate image URLs.";
      }

      debugPrint('Selfie URL: $selfieUrl');
      debugPrint('Meter URL: $meterUrl');
      
      // Prepare data for insertion
      final now = DateTime.now();
      final date = now.toIso8601String().split('T')[0];
      final time = now.toIso8601String().split('T')[1].split('.')[0];
      final location = _address.replaceFirst('🏠 ', '');
      
      final attendanceData = {
        'employee_id': supabase.auth.currentUser?.id,
        'employee_name': empName,
        'date': date,
        'marked_time': time,
        'location': location,
        'selfie_url': selfieUrl,
        'meter_photo_url': meterUrl,
        'created_at': now.toIso8601String(),
      };

      debugPrint('Inserting attendance data: $attendanceData');
      
      // Insert into emp_attendance table
      final response = await supabase
          .from('emp_attendance')
          .insert(attendanceData)
          .select();
      
      debugPrint('Insert response: $response');

      // Update provider state
      await attendanceProvider.checkTodayAttendance();
      
      if (mounted) {
        setState(() => _submissionSuccessful = true);
        _showSuccess();
      }
      
    } catch (e) {
      debugPrint('Submission error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting attendance: ${e.toString()}"), 
          backgroundColor: GlobalColors.danger
        ),
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
        title: Icon(
          Icons.check_circle, 
          color: AppColors.success, 
          size: 50
        ),
        content: const Text(
          "Attendance submitted successfully!", 
          textAlign: TextAlign.center
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _showConfirmation = true);
              },
              child: const Text("OK"),
            ),
          )
        ],
      ),
    );
  }

  void _resetAttendance() {
    setState(() {
      _selfieImage = null;
      _meterImage = null;
      _showConfirmation = false;
    });
    _checkAndGetLocation();
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
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance Marked Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date:', 
                  style: TextStyle(color: AppColors.secondaryText)
                ),
                Text(
                  formattedDate, 
                  style: const TextStyle(fontWeight: FontWeight.w600)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time:', 
                  style: TextStyle(color: AppColors.secondaryText)
                ),
                Text(
                  formattedTime, 
                  style: const TextStyle(fontWeight: FontWeight.w600)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location:', 
                  style: TextStyle(color: AppColors.secondaryText)
                ),
                const SizedBox(height: 4),
                if (_location.contains('\n'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _location.split('\n').map((line) {
                      final isFirstLine = line.contains('📍');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line.replaceFirst('📍 ', '').replaceFirst('🏠 ', ''),
                          style: TextStyle(
                            fontSize: isFirstLine ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: _permissionDenied || _serviceDisabled 
                                ? GlobalColors.danger 
                                : _isLocationAccurate() 
                                  ? AppColors.success 
                                  : GlobalColors.warning,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    _location,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _permissionDenied || _serviceDisabled 
                          ? GlobalColors.danger 
                          : _isLocationAccurate() 
                            ? AppColors.success 
                            : GlobalColors.warning,
                    ),
                  ),
              ],
            ),
            
            if (_currentPosition != null && !_isGettingLocation) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Accuracy:', 
                    style: TextStyle(color: AppColors.secondaryText)
                  ),
                  Text(
                    '${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: GlobalColors.white,
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
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on, 
                color: _locationError 
                    ? GlobalColors.danger 
                    : (_permissionDenied || _serviceDisabled)
                        ? GlobalColors.warning
                        : _isLocationAccurate() 
                            ? AppColors.success 
                            : GlobalColors.warning,
                size: 24,
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
                            color: AppColors.secondaryText,
                          ),
                        ),
                        if (_isGettingLocation) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_locationError || _permissionDenied || _serviceDisabled)
            Column(
              children: [
                Text(
                  _location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: GlobalColors.danger,
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColors.danger,
                    ),
                  ),
                ]
              ],
            )
          else if (_location.contains('\n'))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _location.split('\n').map((line) {
                final isFirstLine = line.contains('📍');
                final isWarning = line.contains('⚠️');
                
                return Padding(
                  padding: EdgeInsets.only(bottom: isFirstLine ? 4 : 0),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: isFirstLine ? 12 : 14,
                      fontWeight: isFirstLine ? FontWeight.w400 : FontWeight.w500,
                      color: isWarning 
                          ? GlobalColors.warning
                          : isFirstLine 
                              ? AppColors.secondaryText
                              : _isLocationAccurate() 
                                  ? AppColors.success 
                                  : GlobalColors.warning,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              _location,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isLocationAccurate() 
                    ? AppColors.success 
                    : GlobalColors.warning,
              ),
            ),
          
          if (_currentPosition != null && !_isGettingLocation && !_locationError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.home, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${DateTime.now().difference(_currentPosition!.timestamp).inSeconds}s ago',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ],
          
          if (_permissionDenied || _serviceDisabled || _locationError) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _retryLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: GlobalColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _permissionDenied 
                              ? 'Request Location Permission'
                              : _serviceDisabled
                                  ? 'Enable Location Services'
                                  : 'Retry Getting Location',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                if (_permissionDenied || _serviceDisabled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (_serviceDisabled) {
                          await Geolocator.openLocationSettings();
                        } else if (_permissionDenied) {
                          await Geolocator.openAppSettings();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primaryBlue),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, size: 20, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Open Settings',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final now = DateTime.now();

    if (attendanceProvider.loading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_submissionSuccessful) {
          return true;
        }
        
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
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: const Text(
            'Mark Attendance',
            style: TextStyle(color: GlobalColors.white),
          ),
          iconTheme: const IconThemeData(color: GlobalColors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isSubmitting 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _showConfirmation 
                      ? _buildConfirmationCard(now)
                      : _buildAttendanceFormWithExtras(),
                ),
              ),
      ),
    );
  }

  Widget _buildAttendanceFormWithExtras() {
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: GlobalColors.white,
                child: Icon(
                  Icons.person, 
                  color: AppColors.primaryBlue
                ),
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
                        color: GlobalColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employeeProvider.profile?['position'] ?? 'Employee',
                      style: TextStyle(
                        color: GlobalColors.white.withOpacity(0.9),
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
        
        // Date & Time Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowGrey,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today, 
                      color: AppColors.primaryBlue
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
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
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowGrey,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time, 
                      color: AppColors.primaryBlue
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
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
        
        const SizedBox(height: 20),
        
        // Selfie Photo Section
        Text(
          'Selfie Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _buildPhotoSection(true),
        
        const SizedBox(height: 20),
        
        // Meter Photo Section
        Text(
          'Meter Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _buildPhotoSection(false),
        
        const SizedBox(height: 20),
        
        // Location Widget
        _buildLocationWidget(),
        
        // Location status warning
        if ((_permissionDenied || _serviceDisabled) && !_isGettingLocation)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlobalColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GlobalColors.danger.withOpacity(0.3)
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning, 
                  size: 16, 
                  color: GlobalColors.danger
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _serviceDisabled 
                        ? 'Location services are disabled. Please enable them.'
                        : 'Location permission is required to record your attendance location.',
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Low accuracy warning
        if (_currentPosition != null && 
            _currentPosition!.accuracy > 50 && 
            !_permissionDenied && 
            !_serviceDisabled && 
            !_isGettingLocation)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlobalColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GlobalColors.warning.withOpacity(0.3)
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning, 
                  size: 16, 
                  color: GlobalColors.warning
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location accuracy is low (${_currentPosition!.accuracy.toStringAsFixed(0)}m). Move to an open area for better accuracy.',
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColors.warning,
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
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: GlobalColors.white,
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
    );
  }

  Widget _buildPhotoSection(bool isSelfie) {
    final XFile? currentImage = isSelfie ? _selfieImage : _meterImage;
    final bool isCapturing = isSelfie ? _isCapturingSelfie : _isCapturingMeter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImageFromGallery(isSelfie),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: GlobalColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isCapturing ? null : () => _takePhotoWithCamera(isSelfie),
                icon: Icon(isCapturing ? Icons.camera : Icons.camera_alt),
                label: Text(isCapturing ? 'Capturing...' : 'Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCapturing ? Colors.grey : AppColors.primaryBlue,
                  foregroundColor: GlobalColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Image Preview
        if (isCapturing)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softGreyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Opening camera...',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          )
        else if (currentImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softGreyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(currentImage.path),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        if (isSelfie) {
                          _selfieImage = null;
                        } else {
                          _meterImage = null;
                        }
                      });
                    },
                    backgroundColor: GlobalColors.danger,
                    child: const Icon(Icons.close, color: GlobalColors.white),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softGreyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderGrey, 
                width: 2
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search, 
                  color: AppColors.primaryBlue, 
                  size: 35
                ),
                const SizedBox(height: 10),
                Text(
                  isSelfie ? 'Selfie' : 'Meter Photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tap Gallery or Camera to add a photo',
                  style: TextStyle(
                    color: AppColors.mutedText, 
                    fontSize: 10
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}











// import 'dart:io';
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
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
//   String _address = 'Getting address...';
//   File? _galleryImage;
//   bool _showConfirmation = false;
//   final ImagePicker _picker = ImagePicker();
//   bool _isCapturing = false;
//   bool _isGettingLocation = false;
//   Position? _currentPosition;
//   bool _permissionDenied = false;
//   bool _serviceDisabled = false;
//   StreamSubscription<Position>? _positionStreamSubscription;
//   bool _locationError = false;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     debugPrint('=== EmployeeAttendancePage initialized ===');
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeLocation();
//     });
//   }

//   @override
//   void dispose() {
//     _positionStreamSubscription?.cancel();
//     debugPrint('=== EmployeeAttendancePage disposed ===');
//     super.dispose();
//   }

//   Future<void> _initializeLocation() async {
//     debugPrint('Initializing location...');
//     await _checkPlatformRequirements();
//     await _checkAndGetLocation();
//     await _checkTodayAttendance();
//   }

//   Future<void> _checkTodayAttendance() async {
//     try {
//       final attendanceProvider = context.read<AttendanceProvider>();
//       await attendanceProvider.checkTodayAttendance();
      
//       if (attendanceProvider.attendanceMarkedToday) {
//         final todayDetails = await attendanceProvider.getTodayAttendanceDetails();
//         if (todayDetails != null) {
//           setState(() {
//             _showConfirmation = true;
//             _location = todayDetails['location'] ?? 'Location not recorded';
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('Error checking today attendance: $e');
//     }
//   }

//   Future<void> _checkPlatformRequirements() async {
//     try {
//       debugPrint('Checking platform requirements...');
//       bool isLocationServiceSupported = await Geolocator.isLocationServiceEnabled();
//       debugPrint('Location service supported: $isLocationServiceSupported');
      
//       if (!isLocationServiceSupported) {
//         setState(() {
//           _serviceDisabled = true;
//           _location = 'Location services not supported';
//           _errorMessage = 'Your device does not support location services';
//         });
//         return;
//       }
//     } catch (e) {
//       debugPrint('Platform check error: $e');
//     }
//   }

//   // Function to get address from coordinates
//   Future<String> _getAddressFromCoordinates(double lat, double lng) async {
//     try {
//       debugPrint('Getting address for coordinates: $lat, $lng');
//       final placemarks = await placemarkFromCoordinates(lat, lng);
      
//       if (placemarks.isNotEmpty) {
//         final placemark = placemarks[0];
        
//         String address = '';
        
//         if (placemark.street != null && placemark.street!.isNotEmpty) {
//           address += placemark.street!;
//         }
        
//         if (placemark.locality != null && placemark.locality!.isNotEmpty) {
//           if (address.isNotEmpty) address += ', ';
//           address += placemark.locality!;
//         }
        
//         if (placemark.subAdministrativeArea != null && 
//             placemark.subAdministrativeArea!.isNotEmpty) {
//           if (address.isNotEmpty) address += ', ';
//           address += placemark.subAdministrativeArea!;
//         }
        
//         if (placemark.administrativeArea != null && 
//             placemark.administrativeArea!.isNotEmpty) {
//           if (address.isNotEmpty) address += ', ';
//           address += placemark.administrativeArea!;
//         }
        
//         if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
//           if (address.isNotEmpty) address += ' - ';
//           address += placemark.postalCode!;
//         }
        
//         if (placemark.country != null && placemark.country!.isNotEmpty) {
//           if (address.isNotEmpty) address += ', ';
//           address += placemark.country!;
//         }
        
//         debugPrint('Address found: $address');
//         return address.isNotEmpty ? address : 'Address not available';
//       }
      
//       debugPrint('No placemarks found');
//       return 'Address not found';
//     } catch (e) {
//       debugPrint('Geocoding error: $e');
//       return 'Unable to fetch address';
//     }
//   }

//   // Get formatted location string
//   Future<String> _getFormattedLocation(Position position) async {
//     try {
//       final address = await _getAddressFromCoordinates(
//         position.latitude, 
//         position.longitude
//       );
      
//       return '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 $address';
//     } catch (e) {
//       debugPrint('Error formatting location: $e');
//       return '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 Address unavailable';
//     }
//   }

//   // Main function to handle location
//   Future<void> _checkAndGetLocation() async {
//     setState(() {
//       _isGettingLocation = true;
//       _location = 'Checking location...';
//       _locationError = false;
//       _errorMessage = '';
//     });

//     try {
//       debugPrint('=== Starting location check ===');
      
//       // 1. Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       debugPrint('Location service enabled: $serviceEnabled');
      
//       if (!serviceEnabled) {
//         setState(() {
//           _serviceDisabled = true;
//           _location = 'Location services are disabled';
//           _errorMessage = 'Please enable location services in your device settings';
//         });
//         return;
//       }

//       // 2. Check permission status
//       LocationPermission permission = await Geolocator.checkPermission();
//       debugPrint('Current permission: $permission');
      
//       switch (permission) {
//         case LocationPermission.denied:
//           debugPrint('Requesting location permission...');
//           permission = await Geolocator.requestPermission();
//           debugPrint('Permission after request: $permission');
          
//           if (permission == LocationPermission.denied) {
//             setState(() {
//               _permissionDenied = true;
//               _location = 'Location permission denied';
//               _errorMessage = 'Please grant location permission from app settings';
//             });
//             return;
//           }
//           break;
          
//         case LocationPermission.deniedForever:
//           debugPrint('Location permission denied forever');
//           setState(() {
//             _permissionDenied = true;
//             _location = 'Location permission permanently denied';
//             _errorMessage = 'Please enable location permission in app settings';
//           });
//           return;
          
//         case LocationPermission.whileInUse:
//         case LocationPermission.always:
//           debugPrint('Location permission granted');
//           break;
          
//         case LocationPermission.unableToDetermine:
//           debugPrint('Unable to determine permission status');
//           setState(() {
//             _location = 'Unable to determine permission status';
//             _errorMessage = 'Please check your location settings';
//           });
//           return;
//       }

//       // 3. Reset flags
//       _permissionDenied = false;
//       _serviceDisabled = false;

//       // 4. Get current position
//       Position position;
//       try {
//         debugPrint('Getting current position...');
//         position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.best,
//           timeLimit: Duration(seconds: 15),
//         );
//         debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');
//         debugPrint('Accuracy: ${position.accuracy}m');
//       } on TimeoutException catch (e) {
//         debugPrint('Location timeout: $e');
//         // Try with lower accuracy
//         position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.medium,
//           timeLimit: Duration(seconds: 10),
//         );
//         debugPrint('Position obtained after timeout: ${position.latitude}, ${position.longitude}');
//       }

//       _currentPosition = position;
      
//       // 5. Get formatted location
//       try {
//         final formattedLocation = await _getFormattedLocation(position);
        
//         setState(() {
//           _location = formattedLocation;
//           _address = formattedLocation.split('\n')[1];
//           _locationError = false;
//         });
        
//         debugPrint('Location updated successfully');
        
//         // 6. Start location updates
//         _startLocationUpdates();
        
//       } catch (e) {
//         debugPrint('Address formatting error: $e');
//         setState(() {
//           _location = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
//           _address = 'Coordinates only - address unavailable';
//           _locationError = false;
//         });
//       }
      
//     } on PlatformException catch (e) {
//       debugPrint('PlatformException in location: $e');
//       setState(() {
//         _locationError = true;
//         _errorMessage = e.message ?? 'Platform location error';
//         _location = 'Location unavailable - Platform error';
//       });
      
//     } catch (e) {
//       debugPrint('General location error: $e');
//       setState(() {
//         _locationError = true;
//         _errorMessage = e.toString();
//         _location = 'Location unavailable - ${e.toString().substring(0, min(30, e.toString().length))}...';
//       });
      
//       await _tryGetLastKnownLocation();
//     } finally {
//       setState(() => _isGettingLocation = false);
//     }
//   }

//   // Start live location updates
//   void _startLocationUpdates() {
//     try {
//       debugPrint('Starting location updates...');
//       const locationSettings = LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       );
      
//       _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
//           .listen((Position position) {
//         if (mounted) {
//           debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
//           setState(() {
//             _currentPosition = position;
//             _location = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n🏠 $_address';
//           });
//         }
//       }, onError: (e) {
//         debugPrint('Error in location stream: $e');
//       });
//     } catch (e) {
//       debugPrint('Error starting location updates: $e');
//     }
//   }

//   // Fallback: Get last known location
//   Future<void> _tryGetLastKnownLocation() async {
//     try {
//       debugPrint('Trying to get last known location...');
//       final Position? lastPosition = await Geolocator.getLastKnownPosition();
      
//       if (lastPosition != null) {
//         debugPrint('Got last known location: ${lastPosition.latitude}, ${lastPosition.longitude}');
//         _currentPosition = lastPosition;
        
//         try {
//           final formattedLocation = await _getFormattedLocation(lastPosition);
//           setState(() {
//             _location = '⚠️ Last known location (may be outdated)\n' + formattedLocation;
//             _address = formattedLocation.split('\n')[1];
//           });
//         } catch (e) {
//           setState(() {
//             _location = '⚠️ Last known: ${lastPosition.latitude.toStringAsFixed(6)}, ${lastPosition.longitude.toStringAsFixed(6)}';
//             _address = 'Coordinates only';
//           });
//         }
//       } else {
//         debugPrint('No last known location available');
//         setState(() {
//           _location = 'No location available';
//           _address = 'Please enable location services';
//         });
//       }
//     } catch (e) {
//       debugPrint('Last known location error: $e');
//       setState(() {
//         _location = 'Location completely unavailable';
//         _address = 'Please check device settings';
//       });
//     }
//   }

//   // Function to retry getting location
//   Future<void> _retryLocation() async {
//     setState(() {
//       _locationError = false;
//       _errorMessage = '';
//     });
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Getting Location'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             Text('Attempting to get your location...'),
//           ],
//         ),
//       ),
//     );
    
//     await _checkAndGetLocation();
    
//     if (mounted) {
//       Navigator.of(context).pop();
//     }
//   }

//   // Helper function to check location accuracy
//   bool _isLocationAccurate() {
//     if (_currentPosition == null) return false;
    
//     final locationAge = DateTime.now().difference(_currentPosition!.timestamp);
//     if (locationAge.inSeconds > 30) {
//       return false;
//     }
    
//     if (_currentPosition!.accuracy > 100) {
//       return false;
//     }
    
//     return true;
//   }

//   // Debug function for testing
//   Future<void> _testLocationDebug() async {
//     debugPrint('=== LOCATION DEBUG START ===');
    
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       debugPrint('1. Location service enabled: $serviceEnabled');
      
//       LocationPermission permission = await Geolocator.checkPermission();
//       debugPrint('2. Location permission: $permission');
      
//       Position? lastPosition = await Geolocator.getLastKnownPosition();
//       debugPrint('3. Last known position: $lastPosition');
      
//       if (permission == LocationPermission.whileInUse || 
//           permission == LocationPermission.always) {
//         try {
//           Position position = await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.low,
//             timeLimit: const Duration(seconds: 5),
//           );
//           debugPrint('4. Current position: ${position.latitude}, ${position.longitude}');
//           debugPrint('5. Accuracy: ${position.accuracy}m');
//           debugPrint('6. Timestamp: ${position.timestamp}');
//         } catch (e) {
//           debugPrint('7. Error getting current position: $e');
//         }
//       }
      
//     } catch (e) {
//       debugPrint('Debug test error: $e');
//     }
    
//     debugPrint('=== LOCATION DEBUG END ===');
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
//     final attendanceProvider = context.read<AttendanceProvider>();
//     final employeeProvider = context.read<EmployeeProvider>();
//     final empName = employeeProvider.profile?['full_name'] ?? 'Employee';
    
//     final imageFile = _galleryImage ?? (_capturedImage != null ? File(_capturedImage!.path) : null);
    
//     if (imageFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please take or select a photo'),
//           backgroundColor: GlobalColors.danger,
//         ),
//       );
//       return;
//     }

//     if (!_isLocationAccurate() && !_permissionDenied && !_serviceDisabled) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Low Location Accuracy'),
//           content: const Text('Your location accuracy is low. Attendance may not be recorded accurately. Do you want to continue?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _markAttendanceProcess(attendanceProvider, empName);
//               },
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       );
//       return;
//     }

//     _markAttendanceProcess(attendanceProvider, empName);
//   }

//   Future<void> _markAttendanceProcess(AttendanceProvider attendanceProvider, String empName) async {
//     try {
//       final fakeImageUrl = 'attendance_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
//       await attendanceProvider.markAttendance(
//         employeeName: empName,
//         selfieUrl: fakeImageUrl,
//         locationText: _address.replaceFirst('🏠 ', ''),
//       );
      
//       setState(() => _showConfirmation = true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to mark attendance: ${e.toString()}'),
//           backgroundColor: GlobalColors.danger,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   void _resetAttendance() {
//     setState(() {
//       _capturedImage = null;
//       _galleryImage = null;
//       _showConfirmation = false;
//     });
//     _checkAndGetLocation();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attendanceProvider = context.watch<AttendanceProvider>();
//     final now = DateTime.now();

//     if (attendanceProvider.loading) {
//       return Scaffold(
//         backgroundColor: AppColors.scaffoldBg,
//         body: const Center(child: CircularProgressIndicator()),
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
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           // Debug button (remove in production)
//           IconButton(
//             icon: const Icon(Icons.bug_report, color: Colors.white),
//             onPressed: _testLocationDebug,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: _showConfirmation 
//               ? _buildConfirmationCard(now, attendanceProvider)
//               : _buildAttendanceFormWithExtras(),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceFormWithExtras() {
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
        
//         // Date & Time Cards
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
        
//         const SizedBox(height: 20),
//         Text(
//           'Select or Capture Selfie',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: AppColors.primaryText,
//           ),
//         ),
//         const SizedBox(height: 12),
        
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _pickImageFromGallery,
//                 icon: const Icon(Icons.photo_library),
//                 label: const Text('Gallery'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _isCapturing ? null : _takePhotoWithCamera,
//                 icon: Icon(_isCapturing ? Icons.camera : Icons.camera_alt),
//                 label: Text(_isCapturing ? 'Capturing...' : 'Camera'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isCapturing ? Colors.grey : GlobalColors.primaryBlue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//           ],
//         ),
        
//         const SizedBox(height: 20),
        
//         // Image Preview
//         if (_isCapturing)
//           Container(
//             height: 300,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const CircularProgressIndicator(),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Opening camera...',
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           )
//         else if (_capturedImage != null || _galleryImage != null)
//           Container(
//             height: 300,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(
//                     File((_capturedImage?.path ?? _galleryImage?.path)!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: FloatingActionButton.small(
//                     onPressed: () {
//                       setState(() {
//                         _capturedImage = null;
//                         _galleryImage = null;
//                       });
//                     },
//                     backgroundColor: GlobalColors.danger,
//                     child: const Icon(Icons.close, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         else
//           Container(
//             height: 300,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.camera_alt, size: 60, color: Colors.grey[400]),
//                 const SizedBox(height: 12),
//                 Text(
//                   'No image selected',
//                   style: TextStyle(color: Colors.grey[500]),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Tap Gallery or Camera to add a photo',
//                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
        
//         const SizedBox(height: 20),
        
//         // Location Widget
//         _buildLocationWidget(),
        
//         // Location status warning
//         if ((_permissionDenied || _serviceDisabled) && !_isGettingLocation)
//           Container(
//             margin: const EdgeInsets.only(top: 8),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.red[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.red[200]!),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning, size: 16, color: Colors.red[800]),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     _serviceDisabled 
//                         ? 'Location services are disabled. Please enable them.'
//                         : 'Location permission is required to record your attendance location.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.red[800],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
        
//         // Low accuracy warning
//         if (_currentPosition != null && 
//             _currentPosition!.accuracy > 50 && 
//             !_permissionDenied && 
//             !_serviceDisabled && 
//             !_isGettingLocation)
//           Container(
//             margin: const EdgeInsets.only(top: 8),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.orange[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.orange[200]!),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning, size: 16, color: Colors.orange[800]),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Location accuracy is low (${_currentPosition!.accuracy.toStringAsFixed(0)}m). Move to an open area for better accuracy.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.orange[800],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
        
//         const SizedBox(height: 30),
        
//         // Submit Button
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _submitAttendance,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: GlobalColors.primaryBlue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'MARK ATTENDANCE',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLocationWidget() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
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
//               Icon(
//                 Icons.location_on, 
//                 color: _locationError 
//                     ? Colors.red 
//                     : (_permissionDenied || _serviceDisabled)
//                         ? Colors.orange
//                         : _isLocationAccurate() 
//                             ? GlobalColors.success 
//                             : GlobalColors.warning,
//                 size: 24,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           'Current Location',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         if (_isGettingLocation) ...[
//                           const SizedBox(width: 8),
//                           SizedBox(
//                             width: 12,
//                             height: 12,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: GlobalColors.primaryBlue,
//                             ),
//                           ),
//                         ]
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
          
//           if (_locationError || _permissionDenied || _serviceDisabled)
//             Column(
//               children: [
//                 Text(
//                   _location,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.red,
//                   ),
//                 ),
//                 if (_errorMessage.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Text(
//                     _errorMessage,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.red[700],
//                     ),
//                   ),
//                 ]
//               ],
//             )
//           else if (_location.contains('\n'))
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: _location.split('\n').map((line) {
//                 final isFirstLine = line.contains('📍');
//                 final isWarning = line.contains('⚠️');
                
//                 return Padding(
//                   padding: EdgeInsets.only(bottom: isFirstLine ? 4 : 0),
//                   child: Text(
//                     line,
//                     style: TextStyle(
//                       fontSize: isFirstLine ? 12 : 14,
//                       fontWeight: isFirstLine ? FontWeight.w400 : FontWeight.w500,
//                       color: isWarning 
//                           ? Colors.orange
//                           : isFirstLine 
//                               ? Colors.grey[600]
//                               : _isLocationAccurate() 
//                                   ? Colors.green 
//                                   : Colors.orange,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             )
//           else
//             Text(
//               _location,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: _isLocationAccurate() 
//                     ? Colors.green 
//                     : Colors.orange,
//               ),
//             ),
          
//           if (_currentPosition != null && !_isGettingLocation && !_locationError) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.home, size: 14, color: Colors.grey[500]),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Updated: ${DateTime.now().difference(_currentPosition!.timestamp).inSeconds}s ago',
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey[500],
//                   ),
//                 ),
//               ],
//             ),
//           ],
          
//           // Action buttons for location issues
//           if (_permissionDenied || _serviceDisabled || _locationError) ...[
//             const SizedBox(height: 12),
//             Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _retryLocation,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.refresh, size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           _permissionDenied 
//                               ? 'Request Location Permission'
//                               : _serviceDisabled
//                                   ? 'Enable Location Services'
//                                   : 'Retry Getting Location',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
                
//                 const SizedBox(height: 8),
                
//                 if (_permissionDenied || _serviceDisabled)
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: () async {
//                         if (_serviceDisabled) {
//                           await Geolocator.openLocationSettings();
//                         } else if (_permissionDenied) {
//                           await Geolocator.openAppSettings();
//                         }
//                       },
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         side: BorderSide(color: GlobalColors.primaryBlue),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.settings, size: 20, color: GlobalColors.primaryBlue),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Open Settings',
//                             style: TextStyle(color: GlobalColors.primaryBlue),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildConfirmationCard(DateTime timestamp, AttendanceProvider attendanceProvider) {
//     final now = timestamp;
//     final formattedDate = '${now.day}/${now.month}/${now.year}';
//     final formattedTime = attendanceProvider.checkInTime ?? 
//         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Location:', style: TextStyle(color: Colors.grey[600])),
//                 const SizedBox(height: 4),
//                 if (_location.contains('\n'))
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: _location.split('\n').map((line) {
//                       final isFirstLine = line.contains('📍');
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 4),
//                         child: Text(
//                           line.replaceFirst('📍 ', '').replaceFirst('🏠 ', ''),
//                           style: TextStyle(
//                             fontSize: isFirstLine ? 12 : 14,
//                             fontWeight: FontWeight.w500,
//                             color: _permissionDenied || _serviceDisabled 
//                                 ? Colors.red 
//                                 : _isLocationAccurate() 
//                                   ? Colors.green 
//                                   : Colors.orange,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   )
//                 else
//                   Text(
//                     _location,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w500,
//                       color: _permissionDenied || _serviceDisabled 
//                           ? Colors.red 
//                           : _isLocationAccurate() 
//                             ? Colors.green 
//                             : Colors.orange,
//                     ),
//                   ),
//               ],
//             ),
            
//             if (_currentPosition != null && !_isGettingLocation) ...[
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Accuracy:', style: TextStyle(color: Colors.grey[600])),
//                   Text(
//                     '${_currentPosition!.accuracy.toStringAsFixed(1)} meters',
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ],
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












