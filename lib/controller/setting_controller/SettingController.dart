import 'dart:convert';

import 'package:get/get.dart';

import '../../model/FaqListModel.dart';
import '../../view/network/ApiService.dart';

class SettingController extends GetxController{

  var faqLoader = false.obs;

  var faq = <Faq>[].obs;

  Future<void> fetchFaq() async {
    faqLoader.value = true;

    final response = await ApiService.get("https://profile.swopband.com/faq/");
    print("Response Fetch Faq--->${response?.body}");

    faqLoader.value = false;

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final List linksJson = data['faq'] ?? [];
        faq.value = linksJson.map((e) => Faq.fromJson(e)).toList();
      } catch (e) {
        Get.snackbar("Error", "Failed to parse faq");
        print("❌ JSON decode error: $e");
      }
    } else {
      Get.snackbar("Error", "Failed to load faq");
    }
  }
  
}