import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:provider/provider.dart';


class LocationController extends ChangeNotifier{
  static LocationController of(BuildContext context) => context.read<LocationController>();
  
  final MethodChannel _channel = const MethodChannel("com.e9friends.inain");

  // final Location _locationPlugin = l.Location();

  // LocationData? _location;
  // LocationData? get location => _location;
  // set location(LocationData? data){
  //   _location = data;
  //   notifyListeners();
  // }

  Future<void> initialLocationSettings(String deviceId) async {
    await _channel.invokeMethod("startService", {
      "device_id": deviceId
    });
  }
}