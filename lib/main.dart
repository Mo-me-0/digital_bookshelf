import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_bookshelf/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize hive
  await Hive.initFlutter();
  
  // storage manager
  await ShelfServices.init();
  
  // start the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bookshelf',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const HomePage(title: 'My Bookshelf'),
    );
  }
}
