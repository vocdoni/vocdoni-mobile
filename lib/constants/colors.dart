import 'package:flutter/material.dart';

final double opacitySecondaryElement = 0.5;
final double opacityDecorationLines = 0.1;
final double opacityBackgroundColor = 0.1;
final double opacityDisabled = 0.6;

final Color colorRed = Color(0xFFFF7C7C);
final Color colorOrange = Color(0xFFFFA800);
final Color colorGreen = Color(0xFF91CD45);
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

final double paddingPage = 32;
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

final String fallbackImageUrlPoll = "https://images.unsplash.com/photo-1444664361762-afba083a4d77?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1651&q=80";
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



double hexStringToHue (String hexSource){
  String short = hexSource.substring(0,8);
  int i = int.parse(short);
  return i * 360 / 0xffffff;
}

Color getAvatarBackgroundColor(String hexSource){
  double saturation = 0.5;
  double lightness = 0.5;
  double hue = hexStringToHue(hexSource);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  return hsl.toColor();
}

Color getAvatarTextColor(String hexSource)
{
  double saturation = 0.5;
  double lightness = 1;
  double hue = hexStringToHue(hexSource);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  return hsl.toColor();
}

getAvatarText(String text){
  return text.substring(0,1);
}