import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/loading-spinner.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// import 'package:qr_mobile_vision/qr_camera.dart';
// import 'package:qr_mobile_vision/qr_mobile_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_scan/r_scan.dart';

import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
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

    Globals.analytics.trackPage("QrScanModal");
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
        title: getText(context, "action.add"), // getText(context, "main.scan")
        showBackButton: true,
        onBackButton: onCancel,
      ),
      body: Builder(builder: (_) {
        if (!(availableCameras is List) || availableCameras.length == 0)
          return _buildMessage(
              context, getText(context, "main.noCamerasAreAvailable"));
        else if (_controller == null || !_controller.value.isInitialized)
          return _buildMessage(
              context, getText(context, "main.pleaseAllowAccessToTheCamera"));
        else if (!hasScanPermissions)
          return _buildMessage(
              context, getText(context, "main.pleaseAllowAccessToTheCamera"));
        else if (!scanning) return _buildLoading(context);

        return SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: paddingPage, vertical: paddingPage),
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp('[ \t]'))
                    ],
                    autocorrect: false,
                    autofocus: false,
                    textCapitalization: TextCapitalization.none,
                    style: TextStyle(
                        fontWeight: fontWeightLight,
                        color: colorDescription,
                        fontSize: 17),
                    decoration: InputDecoration(
                        filled: true,
                        border: _emptyTextInputBorder(),
                        focusedBorder: _emptyTextInputBorder(),
                        enabledBorder: _emptyTextInputBorder(),
                        disabledBorder: _emptyTextInputBorder(),
                        errorBorder: _emptyTextInputBorder(),
                        hintText: getText(context, "main.pasteLinkOrCodeHere")),
                    onSubmitted: onSubmitLink,
                  ),
                ).withBottomPadding(8),
                Text(
                  getText(context, "main.orScanQrCode"),
                  style: TextStyle(
                      fontWeight: fontWeightLight, color: colorDescription),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: paddingPage, horizontal: paddingPage),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40.0),
                    child: OverflowBox(
                      maxHeight: double.infinity,
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: RScanCamera(_controller),
                        // ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(paddingPage),
                  padding: EdgeInsets.all(paddingPage + 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    color: colorDescriptionPale
                        .withOpacity(opacityBackgroundColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        FeatherIcons.plus,
                        size: 36,
                        color: colorDescriptionPale,
                      ),
                      Flexible(
                        child: Text(
                          getText(context, "main.theAddPageAllowsYouToAddLinksCodesAndQRCodesInOrderTo") +
                              ":\n" +
                              "• " +
                              getText(context,
                                  "main.joinAnOrganizationWithAnInviteLink") +
                              "\n" +
                              "• " +
                              getText(context,
                                  "main.findAVotingProcessOrOrganization") +
                              "\n" +
                              "• " +
                              getText(context, "main.restoreABackupAccount"),
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.left,
                          softWrap: true,
                          maxLines: 80,
                          style: TextStyle(
                            color: colorDescription.withOpacity(0.7),
                          ),
                        ).withLeftPadding(10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    print(result.message);
    Future.delayed(Duration(milliseconds: 5))
        .then((_) => Navigator.of(context).pop(result.message));
  }

  onSubmitLink(String input) {
    if (input == null)
      return;
    else if (input is! String) return;

    this.setState(() => scanning = false);

    Future.delayed(Duration(milliseconds: 5))
        .then((_) => Navigator.of(context).pop(input));
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Container(
      child: Center(
        child:
            Text(message ?? getText(context, "main.theCameraIsNotAvailable")),
      ),
    ).withBottomPadding(100);
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(getText(context, "main.processingTheCode")),
        LoadingSpinner().withLeftPadding(30),
      ],
    )).withBottomPadding(100);
  }

  OutlineInputBorder _emptyTextInputBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(color: colorBaseBackground),
      borderRadius: BorderRadius.circular(10),
    );
  }
}
