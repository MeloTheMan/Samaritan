import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

@lazySingleton
class PermissionService {
  Future<bool> requestBluetoothPermission() async {
    final status = await Permission.bluetooth.request();
    if (status.isGranted) return true;

    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    
    return scanStatus.isGranted && connectStatus.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) return true;

    final whenInUseStatus = await Permission.locationWhenInUse.request();
    return whenInUseStatus.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> checkBluetoothPermission() async {
    return await Permission.bluetooth.isGranted ||
        (await Permission.bluetoothScan.isGranted &&
            await Permission.bluetoothConnect.isGranted);
  }

  Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted ||
        await Permission.locationWhenInUse.isGranted;
  }

  Future<bool> checkMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
