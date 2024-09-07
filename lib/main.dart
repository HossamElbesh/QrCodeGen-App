import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

void main() {
  runApp(QRGeneratorApp());
}

class QRGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Generator',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.tealAccent,
        hintColor: Colors.tealAccent,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0),
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
      ),
      home: QRGeneratorScreen(),
    );
  }
}

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _qrData = '';
  bool _showQR = false;
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code Generator',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildTextField(context),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _buttonAnimation,
                child: ElevatedButton.icon(
                  onPressed: _generateQRCode,
                  icon: const Icon(Icons.qr_code, color: Colors.black),
                  label: const Text(
                    'Generate QR Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              AnimatedOpacity(
                opacity: _showQR ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: _showQR
                    ? QRCard(
                  qrData: _qrData,
                  onSave: _saveQRCode,
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20), // Add spacing to avoid overflow
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Container(
      width: isSmallScreen ? double.infinity : 500,
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter A Link Or Text',
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.link, color: Colors.tealAccent),
        ),
      ),
    );
  }

  void _generateQRCode() {
    setState(() {
      _qrData = _controller.text;
      _showQR = _qrData.isNotEmpty;
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    });
  }

  Future<void> _saveQRCode() async {
    try {
      final qrImage = await QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      ).toImage(200);

      ByteData? byteData =
      await qrImage.toByteData(format: ImageByteFormat.png);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final result = await saveImage(buffer);
        if (result == "Image saved to gallery!") {
          showSuccessNotification(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String> saveImage(Uint8List buffer) async {
    try {
      final result = await ImageGallerySaver.saveImage(buffer);
      return "Image saved to gallery!";
    } catch (e) {
      return "Failed to save image: $e";
    }
  }

  void showSuccessNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code saved!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Text.rich(
        TextSpan(
          text: 'Coded By: ',
          style: const TextStyle(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(
              text: 'Hossam Elbesh',
              style: const TextStyle(
                color: Colors.tealAccent,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  Uri url = Uri.parse('https://github.com/HossamElbesh');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
            ),
          ],
        ),
      ),
    );
  }
}

class QRCard extends StatelessWidget {
  final String qrData;
  final VoidCallback onSave;

  const QRCard({required this.qrData, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width < 600 ? 200.0 : 300.0,
            foregroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_alt, color: Colors.black),
            label: const Text(
              'Save QR Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
