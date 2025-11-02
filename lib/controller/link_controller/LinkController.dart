import 'dart:convert';
import 'dart:developer';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import '../../model/FetchAllLinksModel.dart';
import '../../view/network/ApiService.dart';
import '../../view/network/ApiUrls.dart';
import '../../view/utils/shared_pref/SharedPrefHelper.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LinkController extends GetxController {
  var isLoading = false.obs;
  var links = <Link>[].obs;
  var fetchLinkLoader = false.obs;

  // NFC Write Logic
  var nfcWriteInProgress = false.obs;
  var nfcWriteStatus = ''.obs;
  List<NdefRecord> nfcRecords = [];

  void addNfcRecord(NdefRecord record) {
    nfcRecords.add(record);
    update();
  }

  void removeNfcRecord(int index) {
    if (index >= 0 && index < nfcRecords.length) {
      nfcRecords.removeAt(index);
      update();
    }
  }

  Future<void> createLink(
      {required String name,
      required String type,
      required String url,
      required VoidCallback call}) async {
    log("api start");
    isLoading.value = true;
    try {
      final userId = await SharedPrefService.getString('backend_user_id');
      if (userId == null) {
        SnackbarUtil.showError("User ID not found");
        return;
      }

      http.Response? response;

      // Route to dedicated endpoints for email and phone/whatsapp
      if (type.toLowerCase() == 'email') {
        final body = {
          "type": "primary",
          "email": url.trim(),
        };
        log("email body---->$body");
        response = await ApiService.post('${ApiUrls.baseUrl}/emails', body);
      } else if (type.toLowerCase() == 'phone' ||
          type.toLowerCase() == 'whatsapp') {
        final parsed = _parsePhone(url);
        final body = {
          "type": "primary",
          "country_code": parsed["country_code"] ??"",
          "number": parsed["number"] ?? "",
        };
        log("phone body---->$body");
        response =
            await ApiService.post('${ApiUrls.baseUrl}/phone_numbers', body);
      } else {
        final body = {
          "user_id": userId,
          "name": name,
          "type": type,
          "url": url,
        };
        log("link body---->$body");
        response = await ApiService.post(ApiUrls.createLink, body);
      }
      log("create link response---->${response?.body}");
      if (response == null) {
        SnackbarUtil.showError("No response from server");
        return;
      }

      final data = jsonDecode(response.body);
      log("status code----->1${response.statusCode}");
      if (response.statusCode == 200) {
        log("status code----->2${response.statusCode}");
        log("response body${response.body}");
        final message = data['message'] ?? 'Link created';
        call();

        SnackbarUtil.showSuccess(message);
      } else {
        // Check for field-specific errors first
        if (data['errors'] != null && data['errors']['fieldErrors'] != null) {
          final fieldErrors =
              data['errors']['fieldErrors'] as Map<String, dynamic>;

          // Check for URL field error
          if (fieldErrors['url'] != null &&
              fieldErrors['url'] is List &&
              fieldErrors['url'].isNotEmpty) {
            final urlError = fieldErrors['url'][0];
            log("URL field error: $urlError");
            SnackbarUtil.showError(urlError);
            return;
          }

          // Check for other field errors
          for (String field in fieldErrors.keys) {
            if (fieldErrors[field] is List && fieldErrors[field].isNotEmpty) {
              final fieldError = fieldErrors[field][0];
              log("Field error for $field: $fieldError");
              SnackbarUtil.showError(fieldError);
              return;
            }
          }
        }

        // Check for specific error messages and provide better user feedback
        final error =
            data['error'] ?? data['message'] ?? "Something went wrong";
        log("error-->$error");

        // Handle specific error cases with better user guidance
        final errorString = error.toString().toLowerCase();
        if (errorString.contains('duplicate')) {
          SnackbarUtil.showError(
              "This link already exists. Please try a different URL or check your existing links.");
        } else if (errorString.contains('invalid') ||
            errorString.contains('url')) {
          SnackbarUtil.showError(
              "Please enter a valid URL for this link type.");
        } else if (errorString.contains('required') ||
            errorString.contains('missing')) {
          SnackbarUtil.showError("Please fill in all required fields.");
        } else if (response.statusCode == 409) {
          SnackbarUtil.showError(
              "This link already exists in your profile. Please use a different URL.");
        } else {
          SnackbarUtil.showError(error);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> writeNfcTagAndSaveLink({
    required BuildContext context,
    required String name,
    required String type,
    required String url,
  }) async {
    if (nfcRecords.isEmpty) {
      SnackbarUtil.showError('No NFC data to write!');
      return;
    }
    nfcWriteInProgress.value = true;
    nfcWriteStatus.value = 'Waiting for NFC tag...';
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          NfcManager.instance.stopSession(errorMessage: 'Tag not writable');
          nfcWriteStatus.value = 'This tag is not writable';
          nfcWriteInProgress.value = false;
          SnackbarUtil.showError('This tag is not writable');
          return;
        }
        try {
          await ndef.write(NdefMessage(nfcRecords));
          NfcManager.instance.stopSession();
          nfcWriteStatus.value = 'Write successful!';
          nfcWriteInProgress.value = false;
          SnackbarUtil.showSuccess('NFC write successful!');
          // Call backend API to save link
          await createLink(name: name, type: type, url: url, call: () {});
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: e.toString());
          nfcWriteStatus.value = 'Write failed: $e';
          nfcWriteInProgress.value = false;
          SnackbarUtil.showError('Write failed: $e');
        }
      },
    );
  }

  Future<void> fetchLinks() async {
    fetchLinkLoader.value = true;

    final userId = await SharedPrefService.getString('backend_user_id');
    if (userId == null) {
      Get.snackbar("Error", "User ID not found in storage");
      fetchLinkLoader.value = false;
      return;
    }

    try {
      final respLinks =
          await ApiService.get("https://profile.swopband.com/links/");
      final respPhones =
          await ApiService.get("https://profile.swopband.com/phone_numbers");
      final respEmails =
          await ApiService.get("https://profile.swopband.com/emails");

      final List<Link> combined = [];

      if (respLinks != null && respLinks.statusCode == 200) {
        try {
          final data = jsonDecode(respLinks.body);
          final List linksJson = data['links'] ?? [];
          combined
              .addAll(linksJson.map<Link>((e) => Link.fromJson(e)).toList());
        } catch (e) {
          print("❌ JSON decode error (links): $e");
        }
      }

      if (respPhones != null && respPhones.statusCode == 200) {
        try {
          final data = jsonDecode(respPhones.body);
          final List phonesJson = data['phone_numbers'] ?? [];
          combined.addAll(phonesJson.map<Link>((e) {
            final cc = (e['country_code'] ?? '').toString();
            final num = (e['number'] ?? '').toString();
            return Link(
              id: (e['id'] ?? '').toString(),
              userId: (e['user_id'] ?? '').toString(),
              type: 'phone',
              url: "$cc$num",
            );
          }).toList());
        } catch (e) {
          print("❌ JSON decode error (phone_numbers): $e");
        }
      }

      if (respEmails != null && respEmails.statusCode == 200) {
        try {
          final data = jsonDecode(respEmails.body);
          final List emailsJson = data['emails'] ?? [];
          combined.addAll(emailsJson.map<Link>((e) {
            return Link(
              id: (e['id'] ?? '').toString(),
              userId: (e['user_id'] ?? '').toString(),
              type: 'email',
              url: (e['email'] ?? '').toString(),
            );
          }).toList());
        } catch (e) {
          print("❌ JSON decode error (emails): $e");
        }
      }

      // Safely assign after frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        links.value = combined;
      });
    } finally {
      fetchLinkLoader.value = false;
    }
  }

  Future<void> deleteLink(String id, String type) async {
    isLoading.value = true;
    try {
      final String endpoint;
      if (type.toLowerCase() == 'email') {
        endpoint = '${ApiUrls.baseUrl}/emails/$id';
      } else if (type.toLowerCase() == 'phone' ||
          type.toLowerCase() == 'whatsapp') {
        endpoint = '${ApiUrls.baseUrl}/phone_numbers/$id';
      } else {
        endpoint = 'https://profile.swopband.com/links/$id';
      }

      final response = await ApiService.delete(endpoint);
      if (response != null && response.statusCode == 200) {
        SnackbarUtil.showSuccess('Link deleted successfully');
        await fetchLinks();
      } else {
        SnackbarUtil.showError('Failed to delete link');
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to delete link: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLink(
      {required String id, required String type, required String url}) async {
    isLoading.value = true;
    try {
      final userId = await SharedPrefService.getString('backend_user_id');
      if (userId == null) {
        SnackbarUtil.showError('User ID not found');
        return;
      }
      http.Response? response;

      if (type.toLowerCase() == 'email') {
        final body = {
          'type': 'primary',
          'email': url.trim(),
        };
        response = await ApiService.put('${ApiUrls.baseUrl}/emails/$id', body);
      } else if (type.toLowerCase() == 'phone' ||
          type.toLowerCase() == 'whatsapp') {
        final parsed = _parsePhone(url);
        final body = {
          'type': 'primary',
          'country_code': parsed['country_code'] ?? '',
          'number': parsed['number'] ?? '',
        };
        response =
            await ApiService.put('${ApiUrls.baseUrl}/phone_numbers/$id', body);
      } else {
        final body = {
          'user_id': userId,
          'type': type,
          'url': url,
        };
        response = await ApiService.put(
            'https://profile.swopband.com/links/$id', body);
      }
      if (response != null && response.statusCode == 200) {
        SnackbarUtil.showSuccess('Link updated successfully');
        await fetchLinks();
      } else {
        SnackbarUtil.showError('Failed to update link');
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to update link: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, String> _parsePhone(String input) {
    final trimmed = input.trim();
    final reg = RegExp(r"^(\+\d{1,4})?\s*([0-9\-\s]{4,})$");
    final match = reg.firstMatch(trimmed);
    if (match != null) {
      final code = (match.group(1) ?? "+1").replaceAll(" ", "");
      final number = (match.group(2) ?? "").replaceAll(RegExp(r"[^0-9]"), "");
      return {"country_code": code, "number": number};
    }
    final onlyDigits = trimmed.replaceAll(RegExp(r"[^0-9]"), "");
    return {"country_code": "+1", "number": onlyDigits};
  }
}
