import 'package:cloud_firestore/cloud_firestore.dart';

class DamageReport {
  final String? id;
  final String damageType;
  final String description;
  final DateTime? incidentDate;
  final LocationData? location; // Note: LocationData, not GeoPoint
  final String? imageBase64;
  final Timestamp createdAt;

  DamageReport({
    this.id,
    required this.damageType,
    required this.description,
    this.incidentDate,
    this.location, // This should be LocationData
    this.imageBase64,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'damageType': damageType,
      'description': description,
      'incidentDate': incidentDate != null ? Timestamp.fromDate(incidentDate!) : null,
      if (location != null) 'location': location!.toMap(),
      'imageBase64': imageBase64,
      'createdAt': createdAt,
    };
  }

  // Create from Firestore document
  factory DamageReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DamageReport(
      id: doc.id,
      damageType: data['damageType'] ?? '',
      description: data['description'] ?? '',
      incidentDate: data['incidentDate'] is Timestamp
          ? (data['incidentDate'] as Timestamp).toDate()
          : null,
      location: data['location'] != null 
          ? LocationData.fromMap(data['location']) 
          : null,
      imageBase64: data['imageBase64'],
      createdAt: data['createdAt'] is Timestamp 
          ? data['createdAt'] 
          : Timestamp.now(),
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
    };
  }

  // Create from map
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude'],
      longitude: map['longitude'],
      name: map['name'],
    );
  }

  // Convenience method to create from GeoPoint
  factory LocationData.fromGeoPoint(GeoPoint geoPoint, {String? name}) {
    return LocationData(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      name: name,
    );
  }

  // Convert to GeoPoint for Firestore
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}


class DamageReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new damage report
  Future<DocumentReference> addDamageReport(DamageReport report) {
    return _firestore.collection('damage_reports').add(report.toMap());
  }

  // Get all damage reports
  Stream<List<DamageReport>> getDamageReports() {
    return _firestore
        .collection('damage_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DamageReport.fromFirestore(doc))
            .toList());
  }

  // Update an existing damage report
  Future<void> updateDamageReport(DamageReport report) {
    return _firestore
        .collection('damage_reports')
        .doc(report.id)
        .update(report.toMap());
  }

  // Delete a damage report
  Future<void> deleteDamageReport(String reportId) {
    return _firestore.collection('damage_reports').doc(reportId).delete();
  }
}

// Example usage
void createDamageReport() {
  // Using GeoPoint
  DamageReport report1 = DamageReport(
    damageType: 'Pothole',
    description: 'Large pothole near intersection',
    location: LocationData(
      latitude: 37.7749, 
      longitude: -122.4194, 
      name: 'San Francisco Downtown'
    )
  );

  // Or using fromGeoPoint method


  DamageReportService().addDamageReport(report1);
}

