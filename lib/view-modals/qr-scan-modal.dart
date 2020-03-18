import 'package:dvote_common/widgets/loading-spinner.dart';
import "package:flutter/material.dart";
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/extensions.dart';

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
        if (!scanning) return _buildLoading(context);

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
    Future.delayed(Duration(milliseconds: 5))
        .then((_) => Navigator.of(context).pop(value));
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Container(
      child: Center(
        child: Text(message ?? "The camera is not available"),
      ),
    ).withBottomPadding(100);
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("Analyzing the code..."),
        LoadingSpinner().withLeftPadding(30),
      ],
    )).withBottomPadding(100);
  }
}
