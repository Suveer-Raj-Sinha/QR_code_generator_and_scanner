import 'package:flutter/material.dart';
import 'package:qr_code/GenerateQRCode.dart';
import 'package:qr_code/HomePage.dart';
import 'package:qr_code/ScanQRCode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner and Generator',
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => Homepage(),
        '/scanqrcode' : (context) => Scanqrcode(),
        '/generateqrcode' : (context) => Generateqrcode()
      },
      home: const Homepage(),
    );
  }
}
