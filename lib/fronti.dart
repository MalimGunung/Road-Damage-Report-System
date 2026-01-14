import 'package:flutter/material.dart';  
import 'package:flutter_661/main.dart';
import 'package:flutter_661/menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_661/noti.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();
  
  runApp(const RoadDamageReportApp());
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

class RoadDamageReportApp extends StatelessWidget {
  const RoadDamageReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainPage(),
      routes: {
        '/reportDamage': (context) => const AuthenticationPage(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 125, 50),
      body: Stack(
        children: [
          // Road-related decorative elements
          _buildRoadDecorations(),

          // Top Green decorative shape
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 76, 175, 80),
                borderRadius: BorderRadius.circular(150),
              ),
            ).animate()
              .fadeIn(duration: 800.ms)
              .moveY(begin: -50, end: 0),
          ),

          // Bottom Green decorative shape
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 56, 142, 60),
                borderRadius: BorderRadius.circular(175),
              ),
            ).animate()
              .fadeIn(duration: 800.ms)
              .moveY(begin: 50, end: 0),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Text
                _buildAnimatedText('Road', 80, FontWeight.w700, Colors.white)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.5, end: 0),
                
                _buildAnimatedText('Damage', 100, FontWeight.w800, Colors.white)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.5, end: 0),
                
                _buildAnimatedText('Reporting', 80, FontWeight.w600, Colors.white)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms)
                    .slideY(begin: 0.5, end: 0),
                
                _buildAnimatedText('System', 60, FontWeight.w300, Colors.white70)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 800.ms)
                    .slideY(begin: 0.5, end: 0),

                const SizedBox(height: 50),

                // Report Damage Button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/reportDamage');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                      border: Border.all(
                        color: Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Report Damage',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 1000.ms)
                  .scaleXY(begin: 0.8, end: 1)
                  .shake(duration: 500.ms),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Road-related decorative elements
  Widget _buildRoadDecorations() {
    return Stack(
      children: [
        // Scattered road damage-like shapes
        Positioned(
          top: 100,
          left: 30,
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.greenAccent.withOpacity(0.7),
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          right: 50,
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.construction_rounded,
                  color: Colors.green.withOpacity(0.7),
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to create animated text
  Widget _buildAnimatedText(
    String text,
    double fontSize,
    FontWeight fontWeight,
    Color color,
  ) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.3,
        letterSpacing: 1.1,
      ),
    );
  }
}

class NotificationHandler {
  static void setupNotificationHandlers() {
    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification');
      // Show local notification
      _showLocalNotification(message);
    });

    // Background/Terminated app notifications
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app');
      // Navigate to specific page if needed
      _handleNotificationNavigation(message);
    });
  }

  static void _showLocalNotification(RemoteMessage message) {
    // Use a local notification plugin to show the notification
  }

  static void _handleNotificationNavigation(RemoteMessage message) {
    // Navigate to specific page based on notification data
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}