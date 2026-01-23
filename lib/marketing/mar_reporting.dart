import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MarketingManagerAttendancePage extends StatefulWidget {
  const MarketingManagerAttendancePage({super.key});

  @override
  State<MarketingManagerAttendancePage> createState() => _MarketingManagerAttendancePageState();
}

class _MarketingManagerAttendancePageState extends State<MarketingManagerAttendancePage> {
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
  final TextEditingController _enterpriseNameController = TextEditingController();
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
    _enterpriseNameController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _checkPlatformRequirements();
    await _checkAndGetLocation();
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await supabase
          .from('marketing_manager_attendance')
          .select('*')
          .eq('manager_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _showConfirmation = true;
          _location = data['location'] ?? 'Location not recorded';
        });
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
          debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
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

  Future<void> _submitAttendance() async {
    if (_enterpriseNameController.text.isEmpty || _selfieImage == null || _meterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enterprise name, selfie and meter photo are required!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not logged in";

      final String? selfieUrl = await _uploadImage(_selfieImage!, 'selfies');
      final String? meterUrl = await _uploadImage(_meterImage!, 'meters');

      if (selfieUrl == null || meterUrl == null) throw "Could not upload photos.";

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final time = now.toIso8601String().split('T')[1].split('.')[0];

      // Insert into manager_visits table for reporting
      await supabase.from('manager_visits').insert({
        'enterprise_name': _enterpriseNameController.text.trim(),
        'selfie_url': selfieUrl,
        'meter_photo_url': meterUrl,
        'visit_time': DateTime.now().toIso8601String(),
      });

      // Also insert into marketing_manager_attendance table
      await supabase.from('marketing_manager_attendance').insert({
        'manager_id': user.id,
        'manager_name': user.email?.split('@')[0] ?? 'Manager',
        'enterprise_name': _enterpriseNameController.text.trim(),
        'date': today,
        'marked_time': time,
        'location': _address.replaceFirst('🏠 ', ''),
        'selfie_url': selfieUrl,
        'meter_photo_url': meterUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _submissionSuccessful = true);
        _showSuccess();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"), 
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
          "Visit report and attendance submitted successfully!", 
          textAlign: TextAlign.center
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/marketingManagerDashboard');
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
      _enterpriseNameController.clear();
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
                Navigator.pushNamed(context, '/marketingManagerDashboard');
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
    final now = DateTime.now();
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final user = supabase.auth.currentUser;
    final managerName = user?.email?.split('@')[0] ?? 'Manager';

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
        
        body: _isSubmitting 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _showConfirmation 
                    ? _buildConfirmationCard(now)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Manager Info Card
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
                                        managerName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: GlobalColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Marketing Manager',
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
                          
                          // Enterprise Name
                          _buildLabel("Shop / Enterprise Name"),
                          _buildTextField(),
                          
                          const SizedBox(height: 20),
                          
                          // Selfie Photo Section
                          _buildLabel("Selfie Photo"),
                          const SizedBox(height: 12),
                          _buildPhotoSection(true),
                          
                          const SizedBox(height: 20),
                          
                          // Meter Photo Section
                          _buildLabel("Meter Photo"),
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
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submitAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)
                                ),
                              ),
                              child: Text(
                                "SUBMIT VISIT ATTENDANCE", 
                                style: GoogleFonts.poppins(
                                  color: GlobalColors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, 
      style: GoogleFonts.poppins(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        color: AppColors.primaryText
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: AppColors.borderGrey)
      ),
      child: TextField(
        controller: _enterpriseNameController,
        decoration: const InputDecoration(
          hintText: "Enter Enterprise Name", 
          border: InputBorder.none
        ),
      ),
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
                  style: GoogleFonts.poppins(
                    fontSize: 12, 
                    color: AppColors.secondaryText
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