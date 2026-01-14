import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class AppColors {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFFC8E6C9);
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String _locationName = '';

  final MapController _mapController = MapController();

  static const LatLng _defaultLocation = LatLng(4.2105, 101.9758);

  // Location prediction variables
  List<String> _locationPredictions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _fetchLocationPredictions(_searchController.text);
      } else {
        setState(() {
          _locationPredictions.clear();
        });
      }
    });
  }

  Future<void> _fetchLocationPredictions(String input) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$input');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _locationPredictions = results
              .take(5)
              .map<String>((result) => result['display_name'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching location predictions: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        final currentLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = currentLocation;
        });

        _zoomToLocation(currentLocation);
        _fetchLocationName(currentLocation);
      } else {
        setState(() {
          _selectedLocation = _defaultLocation;
        });
        _zoomToLocation(_defaultLocation);
      }
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _selectedLocation = _defaultLocation;
      });
      _zoomToLocation(_defaultLocation);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _zoomToLocation(point);
    _fetchLocationName(point);

    // Automatically pass back location details
    Navigator.pop(context, {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'locationName': _locationName,
      'address': _locationName
    });
  }

  void _zoomToLocation(LatLng location) {
    _mapController.move(location, 12.0);
  }

  Future<void> _fetchLocationName(LatLng location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locationName = data['display_name'] ?? 'Unknown Location';
        });
      }
    } catch (e) {
      print('Error fetching location name: $e');
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final selectedLocation = LatLng(lat, lon);

          setState(() {
            _selectedLocation = selectedLocation;
            _locationName = results[0]['display_name'] ?? 'Unknown Location';
          });

          _zoomToLocation(selectedLocation);

          // Automatically pass back location details
          Navigator.pop(context, {
            'latitude': lat,
            'longitude': lon,
            'locationName': _locationName,
            'address': _locationName
          });
        }
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Pick Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, {
                  'location': _selectedLocation,
                  'locationName': _locationName,
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Location Predictions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search location',
                      hintStyle: TextStyle(color: AppColors.lightGreen),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.primaryGreen),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: AppColors.darkGreen),
                          onPressed: _searchLocation,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),
                ),

                // Location Predictions Dropdown
                if (_locationPredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightGreen.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _locationPredictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(
                              _locationPredictions[index],
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(
                              Icons.location_on,
                              color: AppColors.primaryGreen,
                            ),
                            onTap: () async {
                              final url = Uri.parse(
                                  'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(_locationPredictions[index])}');

                              try {
                                final response = await http.get(url);
                                if (response.statusCode == 200) {
                                  final List<dynamic> results =
                                      json.decode(response.body);
                                  if (results.isNotEmpty) {
                                    final lat = double.parse(results[0]['lat']);
                                    final lon = double.parse(results[0]['lon']);
                                    final selectedLocation = LatLng(lat, lon);

                                    setState(() {
                                      _selectedLocation = selectedLocation;
                                      _locationName =
                                          _locationPredictions[index];
                                      _locationPredictions.clear();
                                      _searchController.clear();
                                    });

                                    _zoomToLocation(selectedLocation);

                                    // Automatically pass back location details
                                    Navigator.pop(context, {
                                      'latitude': lat,
                                      'longitude': lon,
                                      'locationName': _locationName,
                                      'address': _locationName
                                    });
                                  }
                                }
                              } catch (e) {
                                print('Error fetching location details: $e');
                              }
                            });
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map with Enhanced Styling
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? _defaultLocation,
                    initialZoom: 5.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_pin,
                                color: AppColors.primaryGreen,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Location Name Display
          if (_locationName.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGreen, AppColors.accentGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                'Selected: $_locationName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
