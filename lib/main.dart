import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal App',
      theme: ThemeData(
        primaryColor: Colors.blue[300],
        
       
      ),
      home: LoginScreen(), 
    );
  }
}