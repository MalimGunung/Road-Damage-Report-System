import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'package:flutter_661/menu.dart';
import 'package:flutter_661/location_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_661/road_damage_model.dart';
import 'dart:convert'; // Add this import at the top of your file
import 'package:flutter_661/noti.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DamageReportApp());
}

class AppColors {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFFC8E6C9);
}

class DamageReportApp extends StatelessWidget {
  const DamageReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.lightGreen,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.accentGreen.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.lightGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.lightGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.darkGreen, width: 2),
          ),
        ),
      ),
      home: const DamageReportPage(),
    );
  }
}

class DamageReportPage extends StatefulWidget {
  const DamageReportPage({super.key});

  @override
  State<DamageReportPage> createState() => _DamageReportPageState();
}

class _DamageReportPageState extends State<DamageReportPage>
    with SingleTickerProviderStateMixin {
  // Existing controllers
  bool _isLoading = false;
  bool _isLegalAgreementAccepted = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Improved damage type handling
  String _selectedDamageType = 'Pothole'; // Default value
  final TextEditingController _customDamageTypeController =
      TextEditingController();
  final DamageReportService _damageReportService = DamageReportService();

  // List of predefined damage types
  List<String> predefinedDamageTypes = [
    'Pothole',
    'Cracking',
    'Depression',
    'Rutting',
    'Raveling',
    'Other'
  ];

  // Existing variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;
  int _currentSection = 0;

  late AnimationController _animationController;
  late Animation<double> _animation;

  void _resetLegalAgreement({bool clearOtherFields = false}) {
    setState(() {
      _isLegalAgreementAccepted = false;

      // Optionally clear other fields
      if (clearOtherFields) {
        _descriptionController.clear();
        _locationController.clear();
        _selectedImage = null;
        _selectedDate = null;
        _selectedTime = null;
      }
    });
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      List<int> imageBytes = await _selectedImage!.readAsBytes();

      // Check image size
      if (imageBytes.length > 10 * 1024 * 1024) {
        // 10MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image is too large. Max 10MB allowed.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print('Image processing error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _saveDamageReport() async {
    // Validate inputs first
    if (_selectedDamageType.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Process image
      String? imageBase64 =
          _selectedImage != null ? await _uploadImage() : null;

      // Create LocationData with proper latitude and longitude
      LocationData? locationData;

      // Check if latitude and longitude are not empty and valid
      double? latitude = double.tryParse(_latitudeController.text);
      double? longitude = double.tryParse(_longitudeController.text);

      if (!_isLegalAgreementAccepted) {
        // Show a dialog explaining the legal terms
        await _showLegalAgreementDialog();
        return;
      }

      if (_selectedDamageType.isEmpty || _descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_locationController.text.isNotEmpty &&
          latitude != null &&
          longitude != null &&
          latitude != 0 &&
          longitude != 0) {
        locationData = LocationData(
            latitude: latitude,
            longitude: longitude,
            name: _locationController.text);
      }

      DamageReport report = DamageReport(
        damageType: _selectedDamageType,
        description: _descriptionController.text,
        incidentDate: _selectedDate,
        location: locationData,
        imageBase64: imageBase64,
      );

      // Add the damage report
      await _damageReportService.addDamageReport(report);

      // Prepare notification details
      String notificationMessage =
          'New Road Damage: ${_selectedDamageType} at ${_locationController.text}';

      // Send notification
      await _sendReportNotification(
        damageType: _selectedDamageType,
        location: _locationController.text,
        latitude: latitude,
        longitude: longitude,
      );

      // Show a success dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryGreen),
                SizedBox(width: 10),
                Flexible(
                  // Wrap the text with Flexible
                  child: Text(
                    'Damage Report Submitted',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 18, // Adjust font size if needed
                    ),
                    overflow: TextOverflow.ellipsis, // Add overflow handling
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              // Wrap content in SingleChildScrollView
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your damage report has been successfully submitted.'),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                            text: 'Damage Type: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: _selectedDamageType),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                            text: 'Location: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: _locationController.text),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Notification sent to nearby users',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child:
                    Text('OK', style: TextStyle(color: AppColors.primaryGreen)),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => JournalHomePage()),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Show error notification
      await _showNotificationErrorAlert(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showLegalAgreementDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.policy_outlined,
                    color: AppColors.primaryGreen,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Legal Agreement',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'By submitting this road damage report, you confirm:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLegalTermItem(
                      '1. Accuracy of Information',
                      'The details provided are true to the best of my knowledge.',
                    ),
                    _buildLegalTermItem(
                      '2. Good Faith Reporting',
                      'I am submitting this report to genuinely improve road safety.',
                    ),
                    _buildLegalTermItem(
                      '3. Ethical Commitment',
                      'I will not submit false or misleading information.',
                    ),
                    _buildLegalTermItem(
                      '4. Data Confidentiality',
                      'I understand my personal information will be handled confidentially.',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isLegalAgreementAccepted,
                            activeColor: AppColors.primaryGreen,
                            side: BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                            onChanged: (bool? value) {
                              setState(() {
                                _isLegalAgreementAccepted = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'I have read and agree to the legal terms and confidentiality statement',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLegalAgreementAccepted
                        ? AppColors.primaryGreen
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: _isLegalAgreementAccepted
                      ? () {
                          Navigator.of(context).pop();
                          _saveDamageReport(); // Retry saving the report
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLegalTermItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGreen.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

// Notification sending method
  Future<void> _sendReportNotification({
    required String damageType,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Send broadcast notification
      await PushNotificationService.broadcastDamageReport(
        message: 'New Road Damage: $damageType at $location',
        damageType: damageType,
        locationName: location,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      // Log the error or handle it as needed
      print('Notification sending error: $e');
      rethrow;
    }
  }

// Error alert method
  Future<void> _showNotificationErrorAlert(dynamic error) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('Notification Error', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text('Failed to send notification: ${error.toString()}'),
          actions: [
            TextButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose existing controllers
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    // Dispose new controllers
    _customDamageTypeController.dispose();

    super.dispose();
  }

  // Method to handle damage type selection
  void _handleDamageTypeSelection(String? value) {
    if (value == null) return;

    setState(() {
      if (value == 'Other') {
        // Show custom input dialog
        _showCustomDamageTypeDialog();
      } else {
        _selectedDamageType = value;
      }
    });
  }

  // Method to show custom damage type dialog
  void _showCustomDamageTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Damage Type'),
          content: TextField(
            controller: _customDamageTypeController,
            decoration: InputDecoration(
              hintText: 'Enter custom damage type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_customDamageTypeController.text.isNotEmpty) {
                  setState(() {
                    // Remove 'Other' and add the custom type
                    predefinedDamageTypes.remove('Other');
                    predefinedDamageTypes.add(_customDamageTypeController.text);
                    _selectedDamageType = _customDamageTypeController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Method to pick time
  void _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;

        // If date is not selected, set it to today when time is picked
        _selectedDate ??= DateTime.now();
      });
    }
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(0, "Damage Details", Icons.description),
          _buildNavButton(1, "Location", Icons.location_on),
          _buildNavButton(2, "Evidence", Icons.camera_alt),
        ],
      ),
    );
  }

  Widget _buildNavButton(int index, String label, IconData icon) {
    bool isSelected = _currentSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _animationController.forward(from: 0);
          setState(() {
            _currentSection = index;
          });
        },
        child: FadeIn(
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.darkGreen,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderCurrentSection() {
    return FadeTransition(
      opacity: _animation,
      child: _getCurrentSectionWidget(),
    );
  }

  Widget _getCurrentSectionWidget() {
    switch (_currentSection) {
      case 0:
        return _buildDamageDetailsSection();
      case 1:
        return _buildLocationSection();
      case 2:
        return _buildImageSection();
      default:
        return _buildDamageDetailsSection();
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElasticIn(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lightGreen.withOpacity(0.3),
                    AppColors.primaryGreen.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.5),
                ),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 80,
                          color: AppColors.darkGreen.withOpacity(0.7),
                        ),
                        const Text(
                          'Upload Evidence',
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.darkGreen,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? pickedImage =
                    await picker.pickImage(source: ImageSource.camera);
                if (pickedImage != null) {
                  setState(() {
                    _selectedImage = File(pickedImage.path);
                  });
                }
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Method to get description for each damage type
String getDamageTypeDescription(String damageType) {
  switch (damageType) {
    case 'Pothole':
      return 'A pothole is a deep, bowl-shaped hole in a road surface caused by wear, weather, or poor maintenance.';
    case 'Cracking':
      return 'Cracking refers to breaks or fractures in the road surface, which can be linear, alligator-patterned, or block-like.';
    case 'Depression':
      return 'A depression is a localized low area in the road surface that collects water and can cause vehicle damage.';
    case 'Rutting':
      return 'Rutting is a longitudinal groove or depression in the wheel path of a road, typically caused by repeated traffic loading.';
    case 'Raveling':
      return 'Raveling occurs when the road surface loses its aggregate, creating a rough and deteriorating surface.';
    case 'Other':
      return 'A custom or unique type of road damage not covered by standard categories.';
    default:
      return 'Additional details about the damage type.';
  }
}

Widget _buildDamageDetailsSection() {
  // Map of damage types to their corresponding image URLs
  final Map<String, String> damageTypeImages = {
    'Pothole': 'https://www.thomaslawoffices.com/nitropack_static/GSnyMFlSbmzoumOjqIsdQRNhIQBlzGMU/assets/images/optimized/rev-67e9dc5/www.thomaslawoffices.com/wp-content/uploads/2023/01/Whos-liable-in-an-accident-involving-a-pothole.jpg',
    'Cracking': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-XYTI9_E6hA5zUExOVRNUgqj-mGcX4aJQvA&s',
    'Depression': 'https://parkviewdc.com/wp-content/uploads/2012/02/potslab.jpg',
    'Rutting': 'https://www.pavementinteractive.org/wp-content/uploads/2008/05/Subbase_rutting.jpg',
    'Raveling': 'https://www.pavementinteractive.org/wp-content/uploads/2009/04/WSDOT152.jpg',
    'Other': 'https://example.com/other-damage.jpg'
  };

void _showDamageTypeInfo() {
  if (damageTypeImages.containsKey(_selectedDamageType)) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${_selectedDamageType} Damage Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                damageTypeImages[_selectedDamageType]!,
                width: 250,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 250,
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        'Image not available',
                        style: TextStyle(color: AppColors.darkGreen),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Text(
                getDamageTypeDescription(_selectedDamageType),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Damage Type Dropdown with Custom Option and Info Icon
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Damage Type",
                prefixIcon: Icon(Icons.warning_outlined, color: AppColors.primaryGreen),
              ),
              items: predefinedDamageTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              value: _selectedDamageType,
              onChanged: _handleDamageTypeSelection,
              hint: const Text('Select Damage Type'),
              dropdownColor: Colors.white,
              style: TextStyle(color: AppColors.darkGreen),
            ),
          ),
          // Info Icon
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.primaryGreen),
            onPressed: _showDamageTypeInfo,
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Rest of the existing code remains the same...
      TextField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: "Description",
          alignLabelWithHint: true,
          prefixIcon: Icon(Icons.description, color: AppColors.primaryGreen),
        ),
      ),
        const SizedBox(height: 16),

        // Date and Time Selection Row
        Row(
          children: [
            // Date Picker
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Select Date"
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.grey
                              : AppColors.darkGreen,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Time Picker
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime == null
                            ? "Select Time"
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedTime == null
                              ? Colors.grey
                              : AppColors.darkGreen,
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: "Location Name",
            prefixIcon: Icon(Icons.location_on, color: AppColors.primaryGreen),
            hintText: "Enter location name",
            suffixIcon: _locationController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.darkGreen),
                    onPressed: () {
                      setState(() {
                        _locationController.clear();
                        _latitudeController.clear();
                        _longitudeController.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latitudeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Latitude",
                  prefixIcon:
                      Icon(Icons.location_city, color: AppColors.primaryGreen),
                  hintText: "Enter latitude",
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _longitudeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Longitude",
                  prefixIcon:
                      Icon(Icons.location_city, color: AppColors.primaryGreen),
                  hintText: "Enter longitude",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              // Navigate to LocationPickerPage
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationPickerPage(),
                ),
              );

              // Handle the returned location
              if (result != null && result is Map) {
                setState(() {
                  // Safely extract location details
                  _locationController.text = result['locationName'] ??
                      result['address'] ??
                      'Unknown Location';

                  // Set latitude and longitude if available
                  _latitudeController.text =
                      (result['latitude'] ?? 0.0).toString();
                  _longitudeController.text =
                      (result['longitude'] ?? 0.0).toString();
                });
              }
            } catch (e) {
              // Handle any potential errors
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error selecting location: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.map),
          label: const Text("Pick Location on Map"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _locationController.text.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${_locationController.text}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Latitude: ${_latitudeController.text}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGreen.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Longitude: ${_longitudeController.text}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGreen.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Reset legal agreement when navigating away
        setState(() {
          _isLegalAgreementAccepted = false;
          _resetLegalAgreement();
        });
        return !_isLoading;
      },
      child: AbsorbPointer(
        // Prevents user interactions
        absorbing: _isLoading,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Damage Report"),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                // Reset legal agreement when manually navigating back
                setState(() {
                  _isLegalAgreementAccepted = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JournalHomePage(),
                  ),
                );
              },
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightGreen.withOpacity(0.1),
                  AppColors.primaryGreen.withOpacity(0.2),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNavigationBar(),
                  const SizedBox(height: 16),
                  Expanded(child: _renderCurrentSection()),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Reset legal agreement when cancelling
                          setState(() {
                            _isLegalAgreementAccepted = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JournalHomePage(),
                            ),
                          );
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Validate and save damage report
                          _saveDamageReport();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Optional: Add a loading indicator when _isLoading is true
          bottomSheet: _isLoading
              ? LinearProgressIndicator(
                  backgroundColor: AppColors.lightGreen.withOpacity(0.3),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                )
              : null,
        ),
      ),
    );
  }
}
