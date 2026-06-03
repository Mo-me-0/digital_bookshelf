import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_bookshelf/screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize hive
  await Hive.initFlutter();
  
  // storage manager
  await ShelfServices.init();
  
  // initialize firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // initialize google sign in
  await GoogleSignIn.instance.initialize();
  
  // start the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Bookshelf',
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
