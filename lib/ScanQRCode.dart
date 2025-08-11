import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class Scanqrcode extends StatefulWidget {
  const Scanqrcode({super.key});

  @override
  State<Scanqrcode> createState() => _ScanqrcodeState();
}

class _ScanqrcodeState extends State<Scanqrcode> {
  String qrresult = "Scanned data will appear here";

  Future<void> scanQR() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerPage(),
        ),
      );

      if (result != null && result is String) {
        setState(() {
          qrresult = result;
        });
      }
    } on PlatformException {
      setState(() {
        qrresult = "Failed to read QR";
      });
    }
  }

  bool _isURL(String text) {
    final Uri? uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme;
  }

  bool _isUPILink(String text) {
    return text.toLowerCase().startsWith('upi://') ||
        text.toLowerCase().startsWith('upi:') ||
        text.toLowerCase().contains('@upi');
  }

  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  Future<void> _openPaymentApp(String upiLink) async {
    // Standardize the UPI link format
    String processedLink = upiLink;
    if (!upiLink.toLowerCase().startsWith('upi://') &&
        !upiLink.toLowerCase().startsWith('upi:')) {
      processedLink = 'upi://$upiLink';
    }

    final Uri uri = Uri.parse(processedLink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No payment app found to handle this UPI link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLink = _isURL(qrresult);
    final isUPI = _isUPILink(qrresult);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            if (qrresult != "Scanned data will appear here")
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: isLink
                              ? isUPI
                              ? () => _openPaymentApp(qrresult)
                              : () => _openInBrowser(qrresult)
                              : null,
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: qrresult));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Copied to clipboard")),
                            );
                          },
                          child: Text(
                            qrresult,
                            style: TextStyle(
                              color: isLink ? Colors.blue : Colors.black,
                              fontSize: 16,
                              decoration: isLink ? TextDecoration.underline : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.grey),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrresult));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Copied to clipboard")),
                          );
                        },
                      )
                    ],
                  ),
                  if (isLink)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          if (isUPI)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text("Open in Payment App"),
                              onPressed: () => _openPaymentApp(qrresult),
                            ),
                          if (!isUPI)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text("Open in Browser"),
                              onPressed: () => _openInBrowser(qrresult),
                            ),
                        ],
                      ),
                    ),
                ],
              )
            else
              Text(
                qrresult,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: scanQR,
              child: const Text("Scan Code"),
            )
          ],
        ),
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  bool _isURL(String text) {
    final Uri? uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme;
  }

  bool _isUPILink(String text) {
    return text.toLowerCase().startsWith('upi://') ||
        text.toLowerCase().startsWith('upi:') ||
        text.toLowerCase().contains('@upi');
  }

  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  Future<void> _openPaymentApp(String upiLink) async {
    String processedLink = upiLink;
    if (!upiLink.toLowerCase().startsWith('upi://') &&
        !upiLink.toLowerCase().startsWith('upi:')) {
      processedLink = 'upi://$upiLink';
    }

    final Uri uri = Uri.parse(processedLink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No payment app found to handle this UPI link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point camera at QR code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          if (!isScanned) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              setState(() => isScanned = true);
              controller.stop();

              final String scannedValue = barcodes.first.rawValue ?? '';

              final isUPI = _isUPILink(scannedValue);
              final isURL = _isURL(scannedValue);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text("Scan Complete"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(scannedValue),
                      const SizedBox(height: 10),
                      if (isURL && !isUPI)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text("Open in Browser"),
                          onPressed: () {
                            Navigator.pop(context);
                            _openInBrowser(scannedValue);
                            Navigator.pop(context, scannedValue);
                          },
                        ),
                      if (isUPI)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text("Open in Payment App"),
                          onPressed: () {
                            Navigator.pop(context);
                            _openPaymentApp(scannedValue);
                            Navigator.pop(context, scannedValue);
                          },
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, scannedValue);
                      },
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }
}