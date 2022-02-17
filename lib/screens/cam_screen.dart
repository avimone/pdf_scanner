// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pdf_scanner/edge_detection_shape/edge_detection_shape.dart';
import 'package:pdf_scanner/utilities/camera_view.dart';
import 'package:pdf_scanner/utilities/cropping_preview.dart';
import 'package:pdf_scanner/utilities/edge_detector.dart';
import 'package:pdf_scanner/utilities/image_view.dart';
import 'package:simple_edge_detection/edge_detection.dart';

class CamScreen extends StatefulWidget {
  CameraDescription camera;
  CamScreen(this.camera);
  @override
  _CamScreenState createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  GlobalKey imageWidgetKey = GlobalKey();

  CameraController _controller;
  Future<void> _initializeControllerFuture;
  var isLoading = true;
  XFile singleImage;
  List<XFile> multipleImage;
  bool single = true;
  bool multi = false;
  bool captured = false;
  ///////////////////
  CameraController controller;
  List<CameraDescription> cameras;
  String imagePath;
  String croppedImagePath;
  EdgeDetectionResult edgeDetectionResult;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
    setState(() {
      isLoading = false;
    });
  }

  Future _detectEdges(String filePath) async {
    if (!mounted || filePath == null) {
      return;
    }

    setState(() {
      imagePath = filePath;
    });

    EdgeDetectionResult result = await EdgeDetector().detectEdges(filePath);

    setState(() {
      edgeDetectionResult = result;
    });
    // _processImage(filePath, edgeDetectionResult);
  }

  Future _processImage(
      String filePath, EdgeDetectionResult edgeDetectionResult) async {
    if (!mounted || filePath == null) {
      return;
    }

    bool result =
        await EdgeDetector().processImage(filePath, edgeDetectionResult);

    if (result == false) {
      return;
    }

    setState(() {
      imageCache?.clearLiveImages();
      imageCache?.clear();
      croppedImagePath = imagePath;
    });
    print(croppedImagePath);
  }

  Widget _getMainWidget() {
    if (croppedImagePath != null) {
      return ImageView(imagePath: croppedImagePath);
    }

    return ImagePreview(
      imagePath: imagePath,
      edgeDetectionResult: edgeDetectionResult,
    );
  }

  Widget _getEdgePaint(
      AsyncSnapshot<ui.Image> imageSnapshot, BuildContext context) {
    if (imageSnapshot.connectionState == ConnectionState.waiting)
      return Container();

    print("paint");
    if (imageSnapshot.hasError) return Text('Error: ${imageSnapshot.error}');

    if (edgeDetectionResult == null) return Container();

    final keyContext = imageWidgetKey.currentContext;

    if (keyContext == null) {
      return Container();
    }

    final box = keyContext.findRenderObject() as RenderBox;

    return EdgeDetectionShape(
      originalImageSize: Size(imageSnapshot.data.width.toDouble(),
          imageSnapshot.data.height.toDouble()),
      renderedImageSize: Size(box.size.width, box.size.height),
      edgeDetectionResult: edgeDetectionResult,
    );
  }

  Future<ui.Image> loadUiImage(String imageAssetPath) async {
    final Uint8List data = await File(imageAssetPath).readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image image) {
      return completer.complete(image);
    });
    return completer.future;
  }

  openCamera() async {}
  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      EasyLoading.show(status: "Loading...");
    } else {
      EasyLoading.dismiss();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Container(
              child: Center(),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the preview.
                  return Column(
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      (captured && single)
                          ? Expanded(
                              child: Center(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    Center(child: Text('Loading ...')),
                                    Image.file(File(imagePath),
                                        fit: BoxFit.contain,
                                        key: imageWidgetKey),
                                    FutureBuilder<ui.Image>(
                                        future: loadUiImage(imagePath),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<ui.Image> snapshot) {
                                          return _getEdgePaint(
                                              snapshot, context);
                                        }),
                                  ],
                                ),
                              ),
                            )
                          : CameraPreview(
                              _controller,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [],
                              ),
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.only(right: 15),
                            margin: EdgeInsets.only(top: 12, left: 11),
                            child: InkWell(
                              splashColor: Colors.black,
                              onTap: () {
                                setState(() {
                                  single = true;
                                  multi = false;
                                });
                              },
                              child: Text(
                                "SINGLE  ",
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        single ? Colors.orange : Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 15),
                            margin: EdgeInsets.only(top: 12, left: 0),
                            child: InkWell(
                              splashColor: Colors.black,
                              onTap: () {
                                setState(() {
                                  single = false;
                                  multi = true;
                                });
                              },
                              child: Text(
                                "MULTIPLE",
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        multi ? Colors.orange : Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          captured
                              ? Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Image.file(
                                    File(singleImage.path),
                                    width:
                                        MediaQuery.of(context).size.width * .1,
                                    height: MediaQuery.of(context).size.height *
                                        .13,
                                  ),
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width * .1,
                                  height:
                                      MediaQuery.of(context).size.height * .13,
                                ),
                          Container(
                            margin: EdgeInsets.only(
                                left: captured
                                    ? MediaQuery.of(context).size.width * .28
                                    : (MediaQuery.of(context).size.width *
                                            .28) +
                                        10),
                            child: IconButton(
                              icon: Icon(Icons.camera),
                              color: Colors.white,
                              //Image.asset('path/the_image.png'),
                              iconSize: 50,
                              onPressed: () async {
                                // Take the Picture in a try / catch block. If anything goes wrong,
                                // catch the error.
                                try {
                                  // Ensure that the camera is initialized.
                                  await _initializeControllerFuture;

                                  // Attempt to take a picture and then get the location
                                  // where the image file is saved.
                                  final image = await _controller.takePicture();
                                  if (multi) {
                                    multipleImage.add(image);
                                  }
                                  singleImage = image;
                                  setState(() {
                                    captured = true;
                                  });
                                  _detectEdges(image.path);
                                } catch (e) {
                                  // If an error occurs, log the error to the console.
                                  print(e);
                                }
                              },
                            ),
                          ),
                          captured
                              ? Container(
                                  margin: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          .22),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.check),
                                    iconSize: 35,
                                    color: Colors.white,
                                  ),
                                )
                              : Align()
                        ],
                      )
                    ],
                  );
                } else {
                  // Otherwise, display a loading indicator.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
