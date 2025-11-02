import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  Future<void> checkAllPermissions() async {
    // 1. Location permission (geolocator)


    // 2. Camera permission
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }

    // 3. Storage or Photos (iOS/Android)
    if (Platform.isIOS) {
      if (!await Permission.photos.isGranted) {
        await Permission.photos.request();
      }
    } else {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<bool> isPermanentlyDenied(Permission permission) {
    return permission.status.isPermanentlyDenied;
  }
}