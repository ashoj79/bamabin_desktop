import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/config/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData themeData = ThemeData(
  fontFamily: 'dana',
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontFamily: 'dana', fontSize: fontSizeMedium),
    bodyMedium: TextStyle(fontFamily: 'dana', fontSize: fontSizeMedium),
    bodySmall: TextStyle(fontFamily: 'dana', fontSize: fontSizeSmall),
    titleLarge: TextStyle(fontFamily: 'dana', fontSize: fontSizeXXLarge),
    titleMedium: TextStyle(fontFamily: 'dana', fontSize: fontSizeXLarge),
    titleSmall: TextStyle(fontFamily: 'dana', fontSize: fontSizeLarge),
  ),

  colorScheme: ColorScheme.dark(
    primary: blueColor,
    secondary: purpleGrey80,
    surface: backgroundColor,
  ),

  appBarTheme: AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: bgDarkColor,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: bgDarkColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  ),
);
