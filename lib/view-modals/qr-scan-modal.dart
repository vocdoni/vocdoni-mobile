import "package:flutter/material.dart";
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/lib/singletons.dart';

class QrScanModal extends StatefulWidget {
  @override
  _QrScanModalState createState() => _QrScanModalState();
}

class _QrScanModalState extends State<QrScanModal> {
  bool scanning = true;

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("QrScanModal");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: "Vocdoni", // Lang.of(context).get("Scan")
        showBackButton: true,
        onBackButton: onCancel,
      ),
      body: Builder(builder: (_) {
        if (!scanning) return Container();

        return Container(
            child: QrCamera(
          qrCodeCallback: (data) => onScan(data),
          fit: BoxFit.cover,
          formats: [BarcodeFormats.QR_CODE],
          onError: (context, err) =>
              _buildMessage(context, "The camera is not available"),
          notStartedBuilder: (context) =>
              _buildMessage(context, "The camera is not available"),
        ));
      }),
    );
  }

  onCancel() {
    Navigator.of(context).pop(null);
  }

  onScan(String value) {
    this.setState(() => scanning = false);
    Future.delayed(Duration(milliseconds: 50))
        .then((_) => Navigator.of(context).pop(value));
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Container(
      child: Center(
        child: Text(message ?? "The camera is not available"),
      ),
    );
  }
}
