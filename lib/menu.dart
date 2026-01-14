import 'package:flutter/material.dart';
import 'package:flutter_661/road_damage_model.dart';
import 'package:flutter_661/entries.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:flutter_661/detail.dart';
import 'package:flutter_661/near.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_661/notidetail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Damage Reports',
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        scaffoldBackgroundColor: Colors.green[50],
      ),
      home: const JournalHomePage(),
    );
  }
}

class JournalHomePage extends StatefulWidget {
  const JournalHomePage({super.key});

  @override
  _JournalHomePageState createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage> {
  String? _selectedDamageType;

  // Helper method to get color for damage type
  Color _getDamageTypeColor(String damageType) {
    switch (damageType.toLowerCase()) {
      case 'pothole':
        return Colors.red;
      case 'cracking':
        return Colors.orange;
      case 'depression':
        return Colors.blue;
      case 'rutting':
        return Colors.purple;
      case 'raveling':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final DamageReportService _damageReportService = DamageReportService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.green[600], // Set app bar background to a deeper green
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Road',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Care',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Add Report Button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Add New Report',
            onPressed: () {
              _showReportOptions(context);
            },
          ),
          // Nearby Damage Button
          IconButton(
            icon: Icon(Icons.near_me_outlined, color: Colors.white),
            tooltip: 'Nearby Damages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyDamageReportsPage(),
                ),
              );
            },
          ),
          // In your app bar actions, you can add a notification icon:
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              _navigateToNotifications(context);
            },
          ),
        ],
      ),
      drawer: _buildAppDrawer(),
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom Summary Section (previously SliverAppBar content)
          StreamBuilder<List<DamageReport>>(
            stream: _damageReportService.getDamageReports(),
            builder: (context, snapshot) {
              // Calculate damage type counts
              Map<String, int> damageCounts = {};
              int totalReports = 0;

              if (snapshot.hasData) {
                totalReports = snapshot.data!.length;

                // Count damage types
                for (var report in snapshot.data!) {
                  String damageType = report.damageType.toLowerCase();
                  damageCounts[damageType] =
                      (damageCounts[damageType] ?? 0) + 1;
                }
              }

              return SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[800]!,
                        Colors.green[600]!,
                        Colors.green[900]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background image (same as before)
                      Opacity(
                        opacity: 0.5,
                        child: Image.network(
                          'https://plus.unsplash.com/premium_photo-1664547606209-fb31ec979c85?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cm9hZHxlbnwwfHwwfHx8MA%3D%3D',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                        ),
                      ),

                      // Content (similar to previous implementation)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Name with Stylized Text
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Road',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black45,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[100],
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black45,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 10),

                            // Total Reports Counter
                            Text(
                              'Total Reports',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TweenAnimationBuilder<int>(
                              duration: Duration(milliseconds: 1000),
                              tween: IntTween(begin: 0, end: totalReports),
                              builder: (context, value, child) {
                                return Text(
                                  '$value',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black26,
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 20),

                            // Damage Type Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: damageCounts.entries.map((entry) {
                                  Color chipColor =
                                      _getDamageTypeColor(entry.key);
                                  bool isSelected = _selectedDamageType ==
                                      entry.key.toLowerCase();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDamageType =
                                              _selectedDamageType ==
                                                      entry.key.toLowerCase()
                                                  ? null
                                                  : entry.key.toLowerCase();
                                        });
                                      },
                                      child: Chip(
                                        label: Text(
                                          '${entry.key}: ${entry.value}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : chipColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: isSelected
                                            ? chipColor
                                            : chipColor.withOpacity(0.1),
                                        side: BorderSide(
                                          color: isSelected
                                              ? chipColor
                                              : chipColor.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Rest of the existing content (reports list) remains the same
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: StreamBuilder<List<DamageReport>>(
              stream: _damageReportService.getDamageReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  );
                }

                // Filter reports if a damage type is selected
                List<DamageReport> filteredReports = snapshot.data ?? [];
                if (_selectedDamageType != null) {
                  filteredReports = filteredReports
                      .where((report) =>
                          report.damageType.toLowerCase() ==
                          _selectedDamageType)
                      .toList();
                }

                if (filteredReports.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      DamageReport report = filteredReports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDamageReportCard(report),
                      );
                    },
                    childCount: filteredReports.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create New Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReportOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Smart Report',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement settings page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Smart Reporting page coming soon!!'),
                          backgroundColor: const Color.fromARGB(255, 203, 28, 28),
                        ),
                      );
                    },
                  ),
                  _buildReportOptionButton(
                    icon: Icons.map,
                    label: 'Manual',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DamageReportApp(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(30),
            child: Icon(
              Icons.report_off,
              size: 80,
              color: Colors.green[300],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No Damage Reports Yet',
            style: TextStyle(
              fontSize: 22,
              color: Colors.green[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tap the + button to add a new report',
            style: TextStyle(
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Add Report Button
        Container(
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'addReportBtn', // Add unique hero tag
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DamageReportApp(),
                ),
              );
            },
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),

        // Nearest Damage Button
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'nearestDamageBtn', // Add unique hero tag
            onPressed: () {
              // Navigate to Nearby Damage Reports Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyDamageReportsPage(),
                ),
              );
            },
            icon: Icon(Icons.near_me, color: Colors.white),
            label: Text(
              'Nearby Damage',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDamageReportCard(DamageReport report) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DamageReportDetailsPage(report: report),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green.withOpacity(0.05),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading Icon
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 25, 95, 9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(8),
                  child: _buildLeadingIcon(report),
                ),

                SizedBox(width: 16),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.damageType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color.fromARGB(255, 21, 23, 21),
                          letterSpacing: 1.1,
                        ),
                      ),
                      _buildReportDetailRow(
                        icon: Icons.location_on,
                        text: report.location != null
                            ? '${report.location!.name ?? ''} (${report.location!.latitude}, ${report.location!.longitude})'
                            : 'No location provided',
                      ),
                      if (report.incidentDate != null)
                        _buildReportDetailRow(
                          icon: Icons.calendar_today,
                          text: report.incidentDate!
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                    ],
                  ),
                ),

                // Thumbnail Image
                if (report.imageBase64 != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageThumbnail(report.imageBase64!),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[800]!,
                  Colors.green[600]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: currentUser?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            currentUser!.photoURL!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.green[700],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.green[700],
                        ),
                ),
                SizedBox(height: 10),

                // User Name
                Text(
                  currentUser?.displayName ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // User Email
                Text(
                  currentUser?.email ?? 'user@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          _buildDrawerItem(
            icon: Icons.add_circle_outline,
            title: 'New Report',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DamageReportApp(),
                ),
              );
            },
          ),
          Divider(color: Colors.green[100]),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement settings page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings page coming soon!'),
                  backgroundColor: Colors.green[600],
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'About',
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              _navigateToNotifications(context);
            },
          ),
        ],
      ),
    );
  }

// Helper method to create drawer items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.green[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.green[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

// Method to show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'About RoadCare',
            style: TextStyle(
              color: const Color.fromARGB(255, 11, 156, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'RoadCare is a community-driven application to report and track road damages.',
                  style: TextStyle(color: Colors.green[500]),
                ),
                SizedBox(height: 10),
                Text(
                  'Version: 1.5 M',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 16, 121, 21),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(color: Colors.green[700]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportDetailRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.green[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Added a separate method to handle image display with error handling
  Widget _buildImageThumbnail(String base64Image) {
    try {
      return Image.memory(
        base64Decode(base64Image),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported,
            color: Colors.grey[300],
            size: 60,
          );
        },
      );
    } catch (e) {
      return Icon(
        Icons.image_not_supported,
        color: Colors.grey[300],
        size: 60,
      );
    }
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
}
