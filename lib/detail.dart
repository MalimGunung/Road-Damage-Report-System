import 'package:flutter/material.dart';
import 'package:flutter_661/road_damage_model.dart';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';

class DamageReportDetailsPage extends StatelessWidget {
  final DamageReport report;

  const DamageReportDetailsPage({Key? key, required this.report})
      : super(key: key);

  // Helper method to format date and time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.toLocal().year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  // Helper method to ensure two-digit formatting
  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  // Method to get damage type color
  Color _getDamageTypeColor() {
    switch (report.damageType.toLowerCase()) {
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
  Widget build(BuildContext context) {
    final Color damageTypeColor = _getDamageTypeColor();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Animated SliverAppBar
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeIn(child: _buildImageSection()),
            ),
            backgroundColor: damageTypeColor,
          ),

          // Content Sections with Animations
          SliverList(
            delegate: SliverChildListDelegate([
              // Damage Type Overview
              SlideInUp(
                duration: Duration(milliseconds: 500),
                child: _buildDamageTypeOverview(damageTypeColor),
              ),

              // Description Card
              FadeInRight(
                duration: Duration(milliseconds: 600),
                child: _buildDescriptionCard(),
              ),

              // Location Details
              FadeInLeft(
                duration: Duration(milliseconds: 700),
                child: _buildLocationSection(),
              ),

              // Metadata Section
              ElasticIn(
                duration: Duration(milliseconds: 800),
                child: _buildMetadataSection(),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Image Section with FadeIn
  Widget _buildImageSection() {
    return report.imageBase64 != null
        ? Image.memory(
            base64Decode(report.imageBase64!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.white,
                ),
              );
            },
          )
        : Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 100,
                color: Colors.white,
              ),
            ),
          );
  }

  // Damage Type Overview with additional animation
  Widget _buildDamageTypeOverview(Color damageTypeColor) {
    return ZoomIn(
      duration: Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.all(16),
        color: damageTypeColor.withOpacity(0.1),
        child: Row(
          children: [
            FadeIn(
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: damageTypeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.damageType,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: damageTypeColor,
                    ),
                  ),
                  Text(
                    'Road Damage Detected',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: 10),
              Text(
                report.description,
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: 10),
              _buildLocationDetailRow(
                icon: Icons.location_on,
                title: 'Location Name',
                content: report.location?.name ?? 'Not specified',
              ),
              if (report.location != null)
                _buildLocationDetailRow(
                  icon: Icons.map,
                  title: 'Coordinates',
                  content:
                      'Lat: ${report.location!.latitude}, Lng: ${report.location!.longitude}',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetailRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 200, 197, 8)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 5, 13, 5),
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date & Time Report Created',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 4, 11, 4),
                ),
              ),
              SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.create_outlined,
                title: 'Report Created',
                content: _formatDateTime(report.createdAt.toDate()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
