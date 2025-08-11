import 'package:flutter/material.dart';
import 'package:qr_code/ScanQRCode.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Code Scanner and Generator", style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {setState(() {
              Navigator.pushNamed(context, '/scanqrcode');
            });}, child: Text("Scan QR Code")),
            SizedBox(height: 40,),
            ElevatedButton(onPressed: () {
              setState(() {
                Navigator.pushNamed(context, '/generateqrcode');
              });
            }, child: Text("Generate QR Code"))
          ],
        ),
      ),
    );
  }
}
