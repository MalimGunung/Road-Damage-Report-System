import 'package:flutter/material.dart';
import 'package:flutter_661/road_damage_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_661/detail.dart';
import 'package:animations/animations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_661/noti.dart';

class NearbyDamageReportsPage extends StatefulWidget {
  const NearbyDamageReportsPage({Key? key}) : super(key: key);

  @override
  _NearbyDamageReportsPageState createState() =>
      _NearbyDamageReportsPageState();
}

class _NearbyDamageReportsPageState extends State<NearbyDamageReportsPage> {
  Position? _currentPosition;
  List<DamageReport> _nearbyReports = [];
  bool _isLoading = true;
  double _searchRadius = 5.0;

final PushNotificationService _pushNotificationService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    _pushNotificationService.initialize();
    _subscribeToTopic();
    _getCurrentLocation();
    _requestNotificationPermissions();
    _listenForNewReports();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.notification?.title}');
    // Handle the message as required.
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Light green background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.green[700], // Dark green app bar
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Nearby Road Damage',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.green[900]!,
                      offset: Offset(2.0, 2.0),
                    )
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.green.withOpacity(0.2),
                      BlendMode.srcATop,
                    ),
                    child: Image.network(
                      'https://plus.unsplash.com/premium_photo-1664547606209-fb31ec979c85?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cm9hZHxlbnwwfHwwfHx8MA%3D%3D',
                      fit: BoxFit.cover,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.green[900]!.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _getCurrentLocation,
              ),
              _buildRadiusFilterPopupMenu(),
            ],
          ),
          _buildBodyContent(),
        ],
      ),
      floatingActionButton: _buildLocationFAB(),
    );
  }

  Widget _buildRadiusFilterPopupMenu() {
    return PopupMenuButton<double>(
      icon: Icon(Icons.filter_list, color: Colors.white),
      onSelected: (double value) {
        setState(() {
          _searchRadius = value;
          _fetchNearbyReports();
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1.0,
          child: Row(
            children: [
              Icon(Icons.near_me, color: Colors.green),
              SizedBox(width: 10),
              Text('1 km'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 5.0,
          child: Row(
            children: [
              Icon(Icons.near_me, color: Colors.orange),
              SizedBox(width: 10),
              Text('5 km'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 10.0,
          child: Row(
            children: [
              Icon(Icons.near_me, color: Colors.red),
              SizedBox(width: 10),
              Text('10 km'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFAB() {
    return FloatingActionButton(
      onPressed: _getCurrentLocation,
      backgroundColor: Colors.green[600],
      child: Icon(Icons.my_location, color: Colors.white),
      elevation: 10,
    );
  }

  Widget _buildBodyContent() {
    return SliverFillRemaining(
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : _buildNearbyReportsList(),
    );
  }

  Widget _buildNearbyReportsList() {
    if (_nearbyReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 100,
              color: Colors.green[300],
            ),
            SizedBox(height: 20),
            Text(
              'No Nearby Road Damage Reports',
              style: TextStyle(
                fontSize: 22,
                color: Colors.green[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Try expanding the search radius',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _nearbyReports.length,
      itemBuilder: (context, index) {
        DamageReport report = _nearbyReports[index];
        double distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              report.location!.latitude,
              report.location!.longitude,
            ) /
            1000;

        return OpenContainer(
          closedBuilder: (context, openContainer) {
            return _buildReportCard(report, distance, openContainer);
          },
          openBuilder: (context, closeContainer) {
            return DamageReportDetailsPage(report: report);
          },
          closedElevation: 5,
          transitionType: ContainerTransitionType.fadeThrough,
        );
      },
    );
  }

  Widget _buildReportCard(
      DamageReport report, double distance, VoidCallback openContainer) {
    return Card(
      color: Colors.green[100], // Light green card background
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.green[300]!, width: 1),
      ),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: openContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildLeadingIcon(report),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.damageType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 1, 3, 1),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      report.location?.name ?? 'Unknown Location',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${distance.toStringAsFixed(2)} km away',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 174, 2, 2),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.green[900],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(DamageReport report) {
    IconData iconData;
    Color iconColor;

    switch (report.damageType.toLowerCase()) {
      case 'pothole':
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case 'cracking':
        iconData = Icons.splitscreen;
        iconColor = Colors.orange;
        break;
      case 'depression':
        iconData = Icons.arrow_downward;
        iconColor = Colors.blue;
        break;
      case 'rutting':
        iconData = Icons.linear_scale;
        iconColor = Colors.purple;
        break;
      case 'raveling':
        iconData = Icons.texture;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 30,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDisabledDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _fetchNearbyReports();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _fetchNearbyReports() async {
  if (_currentPosition == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('damage_reports').get();

    List<DamageReport> nearbyReports = querySnapshot.docs
        .map((doc) => DamageReport.fromFirestore(doc))
        .where((report) {
      if (report.location == null) return false;

      double distanceInKm = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            report.location!.latitude,
            report.location!.longitude,
          ) /
          1000;

      return distanceInKm <= _searchRadius;
    }).toList();

    // Sort reports by distance
    nearbyReports.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            a.location!.latitude,
            a.location!.longitude,
          ) /
          1000;

      double distanceB = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            b.location!.latitude,
            b.location!.longitude,
          ) /
          1000;

      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _nearbyReports = nearbyReports;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permissions');
  } else {
    print('User denied notification permissions');
  }
}

void _subscribeToTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic('roadDamageAlerts');
  print('Subscribed to roadDamageAlerts topic');
}

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content:
              Text('Please enable location services to find nearby reports.'),
          actions: [
            TextButton(
              child: Text('Enable'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission'),
          content:
              Text('Location permission is required to find nearby reports.'),
          actions: [
            TextButton(
              child: Text('Request Permission'),
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Denied Forever'),
          content: Text('Please enable location permission in settings.'),
          actions: [
            TextButton(
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _listenForNewReports() {
  FirebaseFirestore.instance.collection('damage_reports').snapshots().listen((snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        DamageReport newReport = DamageReport.fromFirestore(change.doc);
        _handleNewReport(newReport);
      }
    }
  });
}

void _handleNewReport(DamageReport report) async {
  if (_currentPosition == null || report.location == null) return;

  double distanceInKm = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        report.location!.latitude,
        report.location!.longitude,
      ) /
      1000;

  if (distanceInKm <= 5) {
    // Trigger push notification
    
  }
}
}
