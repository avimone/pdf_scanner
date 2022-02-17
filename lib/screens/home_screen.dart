import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pdf_scanner/screens/cam_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraDescription firstCamera;
  @override
  void initState() {
    // TODO: implement initState
    autoLoginState();
    super.initState();
  }

  void autoLoginState() async {
    final cameras = await availableCameras();
    firstCamera = cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CamScreen(firstCamera)));
              },
              child: Text("Camera"))),
    );
  }
}
