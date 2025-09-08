import 'package:flutter/material.dart';
import 'dart:async';

import 'package:niit/ui/screens/homepage.dart';



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou image pendant le splash
              Image.asset(
                'assets/img/police_logo.png', // Remplacez par votre logo
                width: 150,
                height: 150,
              ),
              SizedBox(height: 20),
              // Texte ou animation
              Text(
                'Bienvenue sur mon app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

