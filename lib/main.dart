import 'package:flutter/material.dart';

void main() => runApp(const MyApp());


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bookshelf',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.brown),
      ),
      home: const HomePage(title: 'My Bookshelf'),
    );
  }
}

class HomePage extends StatelessWidget{
  final String title;
  const HomePage({super.key, required this.title});
  
  @override
  
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
    );
  }
}
