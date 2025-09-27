import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Globals {
  static double screenHeight = 0;
  static double screenWidth = 0;

  static Color customBlue = Color.fromARGB(255, 49, 91, 242);
  static Color customLightBlue = Color.fromARGB(255, 91, 117, 246);

  static void initialize(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
  }
}
