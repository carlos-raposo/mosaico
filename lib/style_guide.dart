import 'package:flutter/material.dart';

class AppColors {
  // Fundo
  static const lightBackground = Color.fromARGB(255, 247, 250, 255);
  static const darkBackground = Colors.black;

  // AppBar
  static const lightAppBar = Color.fromARGB(255, 202, 220, 238);
  static const darkAppBar = Colors.black;
  static const lightAppBarText = Color.fromARGB(255, 3, 104, 197);
  static const darkAppBarText = Colors.white;
  static const lightAppBarIcon = Color.fromARGB(255, 3, 104, 197);
  static const darkAppBarIcon = Colors.white;

  // Texto principal
  static const lightText = Color.fromARGB(255, 3, 104, 197);
  static const darkText = Colors.white;

  // Barra de progresso
  static const lightProgressBg = Color.fromARGB(255, 190, 215, 241); // Azul Bebe
  static const darkProgressBg = Color(0xFFD1C4E9); // Colors.deepPurple[100]
  static const lightProgress = Color.fromARGB(255, 3, 104, 197);
  static const darkProgress = Colors.deepPurple;

// Card de pontos
static const lightCardTitle = Color.fromARGB(255, 3, 104, 197);
static const darkCardTitle = Color.fromARGB(255, 255, 255, 255); // branco
static const lightCardValue = Color.fromARGB(255, 3, 104, 197);
static const darkCardValue = Color.fromARGB(255, 255, 255, 255); // branco

  // Botões
  static const playButtonBg = Colors.amber;
  static const rankingButtonBgLight = Color.fromARGB(255, 202, 220, 238);
  static const rankingButtonBgDark = Color.fromARGB(255, 202, 220, 238);
  static const buttonTextLight = Color.fromARGB(255, 3, 104, 197);
  static const buttonTextDark = Colors.black;
  static const buttonBgWhite = Color.fromARGB(255, 255, 255, 255); // branco
  static const buttonBgBlue = Color.fromARGB(255, 3, 104, 197);  // Azul
  static const buttonBorderLight = Color.fromARGB(255, 3, 104, 197);
  static const buttonBorderDark = Color.fromARGB(255, 255, 255, 255); // branco

  // Rodapé
  static const footerTextLight = Color.fromARGB(255, 3, 104, 197);
  static const footerTextDark = Color(0xFF9E9E9E); // Colors.grey[500]
}

class AppStyles {
  static TextStyle title(BuildContext context, {bool bold = true}) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.lightText,
          );

  static TextStyle subtitle(BuildContext context) => TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkText
            : AppColors.lightText,
      );

  static TextStyle buttonText(BuildContext context, {double fontSize = 18}) => TextStyle(
        fontSize: fontSize,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.buttonTextDark
            : AppColors.buttonTextLight,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle footer(BuildContext context) => TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.footerTextDark
            : AppColors.footerTextLight,
        fontSize: 12,
      );
}
