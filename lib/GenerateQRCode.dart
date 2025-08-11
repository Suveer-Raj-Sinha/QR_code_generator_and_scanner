import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

class Generateqrcode extends StatefulWidget {
  const Generateqrcode({super.key});

  @override
  State<Generateqrcode> createState() => _GenerateqrcodeState();
}

class _GenerateqrcodeState extends State<Generateqrcode> {
  TextEditingController urlController = TextEditingController();
  GlobalKey qrKey = GlobalKey();
  bool hasGenerated = false;
  Color qrColor = Colors.black;
  Color backgroundColor = Colors.white;
  double qrSize = 200;
  bool isSaving = false;
  bool isSharing = false;

  Future<void> _generateQR() async {
    if (urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some data first')),
      );
      return;
    }
    setState(() {
      hasGenerated = true;
    });
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await Permission.photos.request().isGranted) {
        return true;
      }

      // For Android 10-12 (API 29-32)
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // If permissions were permanently denied
      if (await Permission.photos.isPermanentlyDenied ||
          await Permission.storage.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    }
    return true; // iOS doesn't need these permissions
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final renderObject = qrKey.currentContext?.findRenderObject();
      if (renderObject == null || !(renderObject is RenderRepaintBoundary)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code not ready for capture')),
        );
        return null;
      }

      final boundary = renderObject as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture QR: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _saveQR() async {
    if (!hasGenerated || isSaving) return;
    setState(() => isSaving = true);

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission required to save to gallery'),
            action: SnackBarAction(
              label: 'OPEN SETTINGS',
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      final pngBytes = await _captureQrImage();
      if (pngBytes == null) return;

      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'qr_code_$timeStamp',
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['errorMessage']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _shareQR() async {
    if (!hasGenerated || isSharing) return;
    setState(() => isSharing = true);

    try {
      final pngBytes = await _captureQrImage();
      if (pngBytes == null) return;

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(pngBytes);

      await Share.shareFiles(
        [filePath],
        text: 'Check out this QR Code!\n${urlController.text}',
        subject: 'QR Code',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR: ${e.toString()}')),
      );
    } finally {
      setState(() => isSharing = false);
    }
  }

  void _changeColor(Color newColor, bool isQrColor) {
    setState(() {
      if (isQrColor) {
        qrColor = newColor;
      } else {
        backgroundColor = newColor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate QR Code"),
        centerTitle: true,
        actions: [
          if (hasGenerated) ...[
            IconButton(
              icon: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
              onPressed: isSaving ? null : _saveQR,
              tooltip: 'Save QR Code',
            ),
            IconButton(
              icon: isSharing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.share),
              onPressed: isSharing ? null : _shareQR,
              tooltip: 'Share QR Code',
            ),
          ],
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasGenerated && urlController.text.isNotEmpty)
                Column(
                  children: [
                    RepaintBoundary(
                      key: qrKey,
                      child: Container(
                        color: backgroundColor,
                        padding: const EdgeInsets.all(20),
                        child: QrImageView(
                          data: urlController.text,
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.transparent,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: qrColor,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: qrColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.color_lens),
                          onPressed: () => _showColorPicker(context, true),
                          tooltip: 'Change QR Color',
                          color: qrColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_color_fill),
                          onPressed: () => _showColorPicker(context, false),
                          tooltip: 'Change Background Color',
                          color: backgroundColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () => setState(() {
                            if (qrSize < 300) qrSize += 20;
                          }),
                          tooltip: 'Increase Size',
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out),
                          onPressed: () => setState(() {
                            if (qrSize > 100) qrSize -= 20;
                          }),
                          tooltip: 'Decrease Size',
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: "Enter URL, text, or UPI payment link",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelText: "Data to encode",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null && data.text != null) {
                          setState(() {
                            urlController.text = data.text!;
                          });
                        }
                      },
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateQR,
                child: const Text("Generate QR Code"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context, bool isQrColor) async {
    final List<Color> colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isQrColor ? 'Select QR Color' : 'Select Background Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return GestureDetector(
                onTap: () {
                  _changeColor(color, isQrColor);
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: color,
                  child: (isQrColor && qrColor == color) || (!isQrColor && backgroundColor == color)
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}