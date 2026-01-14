import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;


// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  
  print("Handling a background message: ${message.messageId}");
  print("Background message: ${message.notification?.title}");
  
  // Add any additional background message processing logic here
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get device token
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");

      // Subscribe to road damage alerts topic
      await _firebaseMessaging.subscribeToTopic('roadDamageAlerts');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle messages when the app is in terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _processNotificationData(message);
        }
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("Foreground message received");
    
    // Extract notification details
    String? title = message.notification?.title;
    String? body = message.notification?.body;
    Map<String, dynamic>? data = message.data;

    // Custom foreground message handling
    if (title != null && body != null) {
      _showForegroundNotification(
        title: title,
        body: body,
        data: data,
      );
    }
  }

  void _showForegroundNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // Implement local notification display logic
    print('Foreground Notification: $title - $body');
    // You can use a package like flutter_local_notifications to show foreground notifications
  }

  void _processNotificationData(RemoteMessage message) {
    // Extract and process notification data
    String? damageType = message.data['damageType'];
    String? location = message.data['location'];
    String? latitude = message.data['latitude'];
    String? longitude = message.data['longitude'];

    print('Processed Notification Data:');
    print('Damage Type: $damageType');
    print('Location: $location');
    print('Latitude: $latitude');
    print('Longitude: $longitude');

    // Add your custom logic to handle the notification data
  }

  static Future<void> broadcastDamageReport({
    required String message,
    String? damageType,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Send notification to all subscribed users
      await sendProximityNotification(
        message: message,
        damageType: damageType,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print("Error broadcasting damage report: $e");
    }
  }
  
static Future<String> getServerAccessToken() async {
  // Service account credentials removed from source for security.
  // Provide credentials securely (for example, a local file named 'service_account.json' excluded from version control,
  // or via environment/secret manager) and update this method to load them.
  throw Exception('Service account credentials not configured. See README for setup.');

    List<String> scopes = [

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging",
      "https://www.googleapis.com/auth/firebase.database",
    ];

    final auth.ServiceAccountCredentials credentials =
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
    
    final auth.AuthClient client =
        await auth.clientViaServiceAccount(credentials, scopes);
    
    final auth.AccessCredentials accessCredentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            credentials, scopes, client);

    client.close();

    return accessCredentials.accessToken.data;
  }

  static Future<void> sendProximityNotification({
    required String message,
    String? damageType,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final String serverToken = await getServerAccessToken();

      // FCM endpoint for sending messages
      String endpointFCM = "https://fcm.googleapis.com/v1/projects/roads-b8764/messages:send";
      
      final Map<String, dynamic> notification = {
        'message': {
          'topic': 'roadDamageAlerts',
          'notification': {
            'title': 'New Road Damage Report',
            'body': message,
          },
          'data': {
            'type': 'road_damage',
            'damageType': damageType ?? 'Unknown',
            'location': locationName ?? 'Unknown Location',
            'latitude': latitude?.toString() ?? '',
            'longitude': longitude?.toString() ?? '',
          }
        }
      };

      final http.Response response = await http.post(
        Uri.parse(endpointFCM),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverToken',
        },
        body: jsonEncode(notification)
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      print("Notification sending error: $e");
      rethrow;
    }
  }
}