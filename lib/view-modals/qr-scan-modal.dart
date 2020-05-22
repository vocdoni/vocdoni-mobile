import 'package:dvote_common/widgets/loading-spinner.dart';
import "package:flutter/material.dart";
// import 'package:qr_mobile_vision/qr_camera.dart';
// import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_scan/r_scan.dart';

import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/extensions.dart';

class QrScanModal extends StatefulWidget {
  @override
  _QrScanModalState createState() => _QrScanModalState();
}

class _QrScanModalState extends State<QrScanModal> {
  List<RScanCameraDescription> availableCameras;
  RScanCameraController _controller;
  bool hasScanPermissions = false;
  bool scanning = true;

  @override
  void initState() {
    super.initState();

    canOpenCamera().then((granted) {
      setState(() {
        hasScanPermissions = granted;
      });
      return availableRScanCameras();
    }).then((cams) {
      setState(() {
        availableCameras = cams;
      });

      if (availableCameras != null && availableCameras.length > 0) {
        _controller = RScanCameraController(
            availableCameras[0], RScanCameraResolutionPreset.max);
        _controller.addListener(() => onScan(_controller.result));
        _controller.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
      }
    });

    setState(() {});

    globalAnalytics.trackPage("QrScanModal");
  }

  @override
  void dispose() {
    _controller?.stopScan();
    _controller?.dispose();
    super.dispose();
  }

  Future<bool> canOpenCamera() async {
    final status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: "Vocdoni", // getText(context, "Scan")
        showBackButton: true,
        onBackButton: onCancel,
      ),
      body: Builder(builder: (_) {
        if (!(availableCameras is List) || availableCameras.length == 0)
          return _buildMessage(
              context, getText(context, "No cameras are available"));
        else if (_controller == null || !_controller.value.isInitialized)
          return _buildMessage(
              context, getText(context, "Please, allow access to the camera"));
        else if (!hasScanPermissions)
          return _buildMessage(
              context, getText(context, "Please, allow access to the camera"));
        else if (!scanning) return _buildLoading(context);

        // FUTURE: Preserve aspect ratio

        // return Container(
        //   child: AspectRatio(
        //     aspectRatio: _controller.value.aspectRatio,
        //     child: RScanCamera(_controller),
        //   ),
        // );
        return Container(
          child: RScanCamera(_controller),
        );
      }),
    );
  }

  onCancel() {
    Navigator.of(context).pop(null);
  }

  onScan(RScanResult result) {
    if (!scanning)
      return;
    else if (result == null)
      return;
    else if (!(result.message is String)) return;

    this.setState(() => scanning = false);

    Future.delayed(Duration(milliseconds: 5))
        .then((_) => Navigator.of(context).pop(result.message));
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Container(
      child: Center(
        child: Text(message ?? getText(context, "The camera is not available")),
      ),
    ).withBottomPadding(100);
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(getText(context, "Processing the code...")),
        LoadingSpinner().withLeftPadding(30),
      ],
    )).withBottomPadding(100);
  }
}
