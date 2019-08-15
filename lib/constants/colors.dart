import 'package:flutter/material.dart';

final double opacitySecondaryElement = 0.5;
final double opacityDecorationLines = 0.1;
final double opacityBackgroundColor = 0.1;
final double opacityDisabled = 0.4;

final Color colorRed = Color(0xFFFF7C7C);
final Color colorOrange = Color(0xFFFFA800);
final Color colorGreen = Color(0xFF66DD55);
final Color colorBlue = Color(0xFF66BBEF);

final Color colorRedPale = Color(0xFFFF8282);
final Color colorOrangePale = Color(0xFFFFBE3F);
final Color colorGreenPale = Color(0xFFAADD77);
final Color colorBluePale = Color(0xFF99CCEE);
final Color colorDescriptionPale = Color(0xFFB4B0AD);

final Color colorBaseBackground = Color(0xFFF3F0ED);
final Color colorCardBackround = Colors.white;
final Color colorDescription = Color(0xFF444444);
final Color colorGuide = colorDescription.withOpacity(opacitySecondaryElement);
final Color colorLightGuide =
    colorDescription.withOpacity(opacityDecorationLines);

final Color colorTitle = Color(0xFF000000);
final Color colorChip = Color(0xFFFFEEBF);
final Color colorLink = colorBlue;

final double paddingPage = 24;
final double paddingChip = 4;
final double paddingButton = 8;
final double paddingBadge = 10;
final double paddingIcon = 24;
final double spaceElement = 12;
final double spaceCard = 24;
final double spaceMainAndSecondary = 8;
final double roundedCornerCard = 10;
final double buttonDefaultWidth = 150;

final double iconSizeTinny = 16;
final double iconSizeSmall = 24;
final double iconSizeMedium = 32;
final double iconSizeLarge = 48;

final double fontSizeTitle = 24;
final double fontSizeBase = 18;
final double fontSizeSecondary = 16;

final FontWeight fontWeightLight = FontWeight.w300;
final FontWeight fontWeightRegular = FontWeight.w400;
final FontWeight fontWeightSemiBold = FontWeight.w600;
final FontWeight fontWeightBold = FontWeight.w700;

enum Purpose { NONE, GUIDE, DANGER, WARNING, GOOD, HIGHLIGHT }

Color getColorByPurpose({Purpose purpose, bool isPale = false}) {
  if (isPale) {
    if (purpose == Purpose.NONE) return colorDescriptionPale;
    if (purpose == Purpose.GUIDE) return colorDescriptionPale;
    if (purpose == Purpose.DANGER) return colorRedPale;
    if (purpose == Purpose.WARNING) return colorOrangePale;
    if (purpose == Purpose.GOOD) return colorGreenPale;
    if (purpose == Purpose.HIGHLIGHT) return colorBluePale;
  } else {
    if (purpose == Purpose.NONE) return colorDescription;
    if (purpose == Purpose.GUIDE) return colorGuide;
    if (purpose == Purpose.DANGER) return colorRed;
    if (purpose == Purpose.WARNING) return colorOrange;
    if (purpose == Purpose.GOOD) return colorGreen;
    if (purpose == Purpose.HIGHLIGHT) return colorBlue;
  }
  return colorDescription;
}
