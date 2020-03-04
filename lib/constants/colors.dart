import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

const double opacitySecondaryElement = 0.5;
const double opacityDecorationLines = 0.1;
const double opacityBackgroundColor = 0.1;
const double opacityDisabled = 0.6;

const Color colorRed = Color(0xFFFF7C7C);
const Color colorOrange = Color(0xFFEEAA00);
const Color colorGreen = Color(0xFF91CD45);
const Color colorBlue = Color(0xFF66BBEF);

const Color colorRedPale = Color(0xFFFF8282);
const Color colorOrangePale = Color(0xFFFFBE3F);
const Color colorGreenPale = Color(0xFFAADD77);
const Color colorBluePale = Color(0xFF99CCEE);
const Color colorDescriptionPale = Color(0xFFB4B0AD);

const Color colorBaseBackground = Color(0xFFF3F0ED);
const Color colorCardBackround = Colors.white;
const Color colorDescription = Color(0xFF444444);
// final Color colorGuide = colorDescription.withOpacity(opacitySecondaryElement);
const Color colorGuide =
    Color(0xB3444444); // opacitySecondaryElement + colorDescription
// final Color colorLightGuide = colorDescription.withOpacity(opacityDecorationLines);
const Color colorLightGuide =
    Color(0x20444444); // opacityDecorationLines + colorDescription

const Color colorTitle = Color(0xFF000000);
const Color colorChip = Color(0xFFFFEEBF);
const Color colorLink = colorBlue;

const double paddingPage = 16;
const double paddingChip = 4;
const double paddingButton = 8;
const double paddingBubble = 12;
const double paddingBadge = 10;
const double paddingIcon = 20;
const double paddingAvatar = 18;
const double spaceElement = 12;
const double spaceCard = 24;
const double spaceMainAndSecondary = 8;
const double roundedCornerCard = 10;
const double roundedCornerBubble = 16;
const double buttonDefaultWidth = 150;

const double iconSizeTinny = 16;
const double iconSizeSmall = 24;
const double iconSizeMedium = 32;
const double iconSizeLarge = 48;
const double iconSizeHuge = 128;

const double fontSizeTitle = 24;
const double fontSizeBase = 16;
const double fontSizeSecondary = 14;

const FontWeight fontWeightLight = FontWeight.w300;
const FontWeight fontWeightRegular = FontWeight.w400;
const FontWeight fontWeightSemiBold = FontWeight.w600;
const FontWeight fontWeightBold = FontWeight.w700;

const String fallbackImageUrlPoll =
    "https://images.unsplash.com/photo-1444664361762-afba083a4d77?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1651&q=80";
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

double hexStringToHue(String source) {
  var bytes = utf8.encode(source); // data being hashed
  var hexSource = sha256.convert(bytes);
  String short = hexSource.toString().substring(0, 6);
  int i = int.parse(short, radix: 16);
  return i * 360 / 0xffffff;
}

Color getAvatarBackgroundColor(String source) {
  double saturation = 1;
  double lightness = 0.7;
  double hue = hexStringToHue(source);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  Color rgb = hsl.toColor();
  Color tint = Colors.orange;
  Color tinted = dye(rgb, tint, 0.5);
  return tinted;
}

Color getAvatarTextColor(String source) {
  double saturation = 1;
  double lightness = 0.2;
  double hue = hexStringToHue(source);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  Color rgb = hsl.toColor();
  Color tint = Colors.orange;
  Color tinted = dye(rgb, tint, 0.5);
  return tinted;
}

Color getHeaderColor(String source) {
  double saturation = 1;
  double lightness = 0.9;
  double hue = hexStringToHue(source);
  HSLColor hsl = HSLColor.fromAHSL(1, hue, saturation, lightness);
  Color rgb = hsl.toColor();
  Color tint = Colors.orange;
  Color tinted = dye(rgb, tint, 0.3);
  return tinted;
}

Color dye(Color original, Color tint, double strength) {
  int red =
      (original.red * (1 - strength)).toInt() + (tint.red * strength).toInt();
  int green = (original.green * (1 - strength)).toInt() +
      (tint.green * strength).toInt();
  int blue =
      (original.blue * (1 - strength)).toInt() + (tint.blue * strength).toInt();
  return Color.fromARGB(original.alpha, red, green, blue);
}
