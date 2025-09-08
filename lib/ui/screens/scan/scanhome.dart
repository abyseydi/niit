import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plate Recognition',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const PlateRecognition(),
    );
  }
}

class PlateRecognition extends StatefulWidget {
  const PlateRecognition({super.key});

  @override
  _PlateRecognitionState createState() => _PlateRecognitionState();
}

class _PlateRecognitionState extends State<PlateRecognition> {
  String recognizedPlate = "";
  bool isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Function to open the camera and process the image
  Future<void> _openCamera() async {
    // Check and request camera permission
    var status = await Permission.camera.request();
    if (status.isDenied) {
      setState(() {
        recognizedPlate = "Permission de la caméra refusée.";
        isProcessing = false;
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        recognizedPlate = "Permission refusée de façon permanente. Veuillez l'activer dans les paramètres.";
        isProcessing = false;
      });
      openAppSettings(); // Open app settings to let the user enable the permission
      return;
    }

    setState(() {
      isProcessing = true;
      recognizedPlate = ""; // Clear previous result
    });

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final inputImage = InputImage.fromFile(File(photo.path));
      try {
        final RecognizedText recognizedText =
            await _textRecognizer.processImage(inputImage);
        
        String plateCandidate = "";
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            if (line.text.length > plateCandidate.length) {
                plateCandidate = line.text;
            }
          }
        }
        
        setState(() {
          recognizedPlate = plateCandidate.isNotEmpty
              ? plateCandidate
              : "Aucune plaque détectée";
        });
      } catch (e) {
        setState(() {
          recognizedPlate = "Erreur de reconnaissance : $e";
        });
        print("Error during text recognition: $e");
      }
    } else {
      setState(() {
        recognizedPlate = "Capture annulée.";
      });
    }

    setState(() {
      isProcessing = false;
    });
  }

  void _reset() {
    setState(() {
      recognizedPlate = "";
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saisie Plaque d’Immatriculation"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Zone de capture
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey, width: 2),
                ),
                child: Center(
                  child: isProcessing
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.camera_alt,
                          size: 100, color: Colors.blueGrey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Résultat
            Text(
              recognizedPlate.isEmpty
                  ? "Aucune plaque détectée"
                  : "Plaque reconnue : $recognizedPlate",
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera),
                  label: const Text("Scanner"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Réinitialiser"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
