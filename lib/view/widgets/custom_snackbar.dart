import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtil {
  static void showError(String message) {
    Get.snackbar(
      "Failed",
      message,
      backgroundColor: Colors.black,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message) {
    Get.snackbar(
      "✅ Success",
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfo(String message) {
    Get.snackbar(
      "ℹ️ Info",
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  static void showWarning(String message) {
    Get.snackbar(
      "⚠️ Warning",
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}