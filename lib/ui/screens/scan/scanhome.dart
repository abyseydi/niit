// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Plate Recognition',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
//         useMaterial3: true,
//       ),
//       home: const PlateRecognition(),
//     );
//   }
// }

// class PlateRecognition extends StatefulWidget {
//   const PlateRecognition({super.key});

//   @override
//   _PlateRecognitionState createState() => _PlateRecognitionState();
// }

// class _PlateRecognitionState extends State<PlateRecognition> {
//   String recognizedPlate = "";
//   bool isProcessing = false;

//   final ImagePicker _picker = ImagePicker();
//   final TextRecognizer _textRecognizer =
//       TextRecognizer(script: TextRecognitionScript.latin);

//   // Function to open the camera and process the image
//   Future<void> _openCamera() async {
//     // Check and request camera permission
//     var status = await Permission.camera.request();
//     if (status.isDenied) {
//       setState(() {
//         recognizedPlate = "Permission de la caméra refusée.";
//         isProcessing = false;
//       });
//       return;
//     }

//     if (status.isPermanentlyDenied) {
//       setState(() {
//         recognizedPlate = "Permission refusée de façon permanente. Veuillez l'activer dans les paramètres.";
//         isProcessing = false;
//       });
//       openAppSettings(); // Open app settings to let the user enable the permission
//       return;
//     }

//     setState(() {
//       isProcessing = true;
//       recognizedPlate = ""; // Clear previous result
//     });

//     final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

//     if (photo != null) {
//       final inputImage = InputImage.fromFile(File(photo.path));
//       try {
//         final RecognizedText recognizedText =
//             await _textRecognizer.processImage(inputImage);

//         String plateCandidate = "";
//         for (TextBlock block in recognizedText.blocks) {
//           for (TextLine line in block.lines) {
//             if (line.text.length > plateCandidate.length) {
//                 plateCandidate = line.text;
//             }
//           }
//         }

//         setState(() {
//           recognizedPlate = plateCandidate.isNotEmpty
//               ? plateCandidate
//               : "Aucune plaque détectée";
//         });
//       } catch (e) {
//         setState(() {
//           recognizedPlate = "Erreur de reconnaissance : $e";
//         });
//         print("Error during text recognition: $e");
//       }
//     } else {
//       setState(() {
//         recognizedPlate = "Capture annulée.";
//       });
//     }

//     setState(() {
//       isProcessing = false;
//     });
//   }

//   void _reset() {
//     setState(() {
//       recognizedPlate = "";
//     });
//   }

//   @override
//   void dispose() {
//     _textRecognizer.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Saisie Plaque d’Immatriculation"),
//         backgroundColor: Colors.blueGrey,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Zone de capture
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.blueGrey, width: 2),
//                 ),
//                 child: Center(
//                   child: isProcessing
//                       ? const CircularProgressIndicator()
//                       : const Icon(Icons.camera_alt,
//                           size: 100, color: Colors.blueGrey),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Résultat
//             Text(
//               recognizedPlate.isEmpty
//                   ? "Aucune plaque détectée"
//                   : "Plaque reconnue : $recognizedPlate",
//               style:
//                   const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             // Boutons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _openCamera,
//                   icon: const Icon(Icons.camera),
//                   label: const Text("Scanner"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueGrey,
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _reset,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text("Réinitialiser"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.redAccent,
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class PlateRecognitionScreen extends StatefulWidget {
  const PlateRecognitionScreen({super.key});

  @override
  State<PlateRecognitionScreen> createState() => _PlateRecognitionScreenState();
}

class _PlateRecognitionScreenState extends State<PlateRecognitionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  String _recognizedText = "Prenez une photo pour scanner une plaque.";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        _showErrorDialog("Aucune caméra disponible.", context);
      }
      _initializeControllerFuture = Future.value();
      return;
    }
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        })
        .catchError((e) {
          if (mounted) {
            _showErrorDialog("Erreur de la caméra: $e", context);
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _showErrorDialog(String message, context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Erreur"),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _takePictureAndScan() async {
    if (!_controller.value.isInitialized || _isProcessing) {
      return;
    }
    setState(() {
      _isProcessing = true;
      _recognizedText = "Scanning...";
    });
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognisedText = await _textRecognizer.processImage(inputImage);

      // Basic filtering to find potential license plates (letters and numbers)
      String foundPlate = "Aucune plaque détectée.";
      for (var block in recognisedText.blocks) {
        String text = block.text.replaceAll(
          RegExp(r'\s+'),
          '',
        ); // Remove spaces
        // Simple regex to match common plate formats (e.g., AB-123-CD, 123-AB-45)
        if (RegExp(
          r'^[A-Z]{1,2}-?[0-9]{1,4}-?[A-Z]{1,2}$',
          caseSensitive: false,
        ).hasMatch(text)) {
          foundPlate = text;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _recognizedText = foundPlate;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Erreur lors du scan: $e", context);
        setState(() {
          _recognizedText = "Échec du scan.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Plaques')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _recognizedText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            backgroundColor: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        FloatingActionButton(
                          onPressed: _isProcessing ? null : _takePictureAndScan,
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
