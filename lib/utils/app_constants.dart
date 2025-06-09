import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF42A5F5); // Biru Langit
  static const Color accentColor = Color(0xFFFFC107); // Kuning Cerah
  static const Color backgroundColor = Color(0xFFF5F5F5); // Abu-abu Terang
  static const Color cardColor = Color(0xFFFFFFFF); // Putih
  static const Color textColor = Color(0xFF333333); // Abu-abu Gelap
  static const Color subtitleColor = Color(0xFF757575); // Abu-abu Sedang
  static const Color successColor = Color(0xFF66BB6A); // Hijau
  static const Color dangerColor = Color(0xFFEF5350); // Merah
  static const Color buttonColor = Color(0xFF42A5F5); // Sama dengan primaryColor
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.subtitleColor,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primaryColor, Color(0xFF2196F3)], // Dari Biru Langit ke Biru standar
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [AppColors.accentColor, Color(0xFFFFCA28)], // Dari Kuning Cerah ke Kuning standar
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardColor,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3), // Pergeseran bayangan
      ),
    ],
  );

  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.dangerColor, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.dangerColor, width: 2),
    ),
    labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor),
    hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.subtitleColor.withOpacity(0.7)),
  );
} 