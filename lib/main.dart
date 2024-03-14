import 'package:emindmatterssystem/screens/WelcomePage.dart';
import 'package:emindmatterssystem/screens/home/BottomNavBarPage.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_app_check/firebase_app_check.dart';

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({required this.initialPage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Mind Matters System',
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColors,
        primaryColor: pShadeColor9,
      ),
      home: initialPage, // Use the home property here
      routes: {
        '/welcome': (context) => const WelcomePage(),
      },
    );
  }
}

void main() async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate();

  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  Widget initialPage = user != null ? BottomNavBarPage() : WelcomePage();

  runApp(MyApp(initialPage: initialPage));
}