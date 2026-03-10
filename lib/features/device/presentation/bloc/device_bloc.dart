import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/entities/wearable_device.dart';
import '../../domain/entities/vital_signs.dart';
import 'device_event.dart';
import 'device_state.dart';

@injectable
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository repository;
  
  WearableDevice? _currentDevice;
  List<VitalSigns> _vitalSignsHistory = [];

  DeviceBloc({required this.repository}) : super(const DeviceInitial()) {
    on<StartDeviceScan>(_onStartDeviceScan);
    on<StopDeviceScan>(_onStopDeviceScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectFromDevice>(_onDisconnectFromDevice);
    on<StartVitalSignsMonitoring>(_onStartVitalSignsMonitoring);
    on<StopVitalSignsMonitoring>(_onStopVitalSignsMonitoring);
    on<UpdateDeviceSettings>(_onUpdateDeviceSettings);
    on<LoadDeviceSettings>(_onLoadDeviceSettings);
    on<LoadVitalSignsHistory>(_onLoadVitalSignsHistory);
    on<UpdateFirmware>(_onUpdateFirmware);
    on<LoadConnectedDevice>(_onLoadConnectedDevice);
  }

  Future<void> _onStartDeviceScan(
    StartDeviceScan event,
    Emitter<DeviceState> emit,
  ) async {
    emit(const DeviceScanning());
    
    try {
      await emit.forEach<Either<Failure, List<WearableDevice>>>(
        repository.scanForDevices(timeout: event.timeout),
        onData: (result) {
          return result.fold(
            (failure) => DeviceError(message: failure.message),
            (devices) => DeviceScanning(devices: devices),
          );
        },
        onError: (error, stackTrace) {
          return DeviceError(message: error.toString());
        },
      );
    } catch (e) {
      emit(DeviceError(message: e.toString()));
    }
  }

  Future<void> _onStopDeviceScan(
    StopDeviceScan event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.stopScan();
    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (_) {
        if (state is DeviceScanning) {
          final devices = (state as DeviceScanning).devices;
          emit(DeviceScanComplete(devices));
        }
      },
    );
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceConnecting(event.deviceId));
    
    final result = await repository.connectToDevice(event.deviceId);
    
    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (device) {
        _currentDevice = device;
        emit(DeviceConnected(device: device));
        
        // Automatically start monitoring vital signs
        add(StartVitalSignsMonitoring(device.id));
        
        // Load device settings
        add(LoadDeviceSettings(device.id));
      },
    );
  }

  Future<void> _onDisconnectFromDevice(
    DisconnectFromDevice event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.disconnectFromDevice(event.deviceId);
    
    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (_) {
        _currentDevice = null;
        _vitalSignsHistory = [];
        emit(const DeviceDisconnected());
      },
    );
  }

  Future<void> _onStartVitalSignsMonitoring(
    StartVitalSignsMonitoring event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await emit.forEach<Either<Failure, VitalSigns>>(
        repository.getVitalSignsStream(event.deviceId),
        onData: (result) {
          return result.fold(
            (failure) => DeviceError(
              message: failure.message,
              device: _currentDevice,
            ),
            (vitalSigns) {
              // Add to history
              _vitalSignsHistory.insert(0, vitalSigns);
              
              // Keep only last 100 readings in memory
              if (_vitalSignsHistory.length > 100) {
                _vitalSignsHistory = _vitalSignsHistory.sublist(0, 100);
              }
              
              if (_currentDevice != null) {
                final updatedDevice = _currentDevice!.copyWith(
                  currentVitalSigns: vitalSigns,
                );
                _currentDevice = updatedDevice;
                
                return DeviceVitalSignsUpdated(
                  device: updatedDevice,
                  vitalSigns: vitalSigns,
                  history: List.from(_vitalSignsHistory),
                );
              }
              
              return DeviceError(
                message: 'No device connected',
                device: _currentDevice,
              );
            },
          );
        },
        onError: (error, stackTrace) {
          return DeviceError(
            message: error.toString(),
            device: _currentDevice,
          );
        },
      );
    } catch (e) {
      emit(DeviceError(
        message: e.toString(),
        device: _currentDevice,
      ));
    }
  }

  Future<void> _onStopVitalSignsMonitoring(
    StopVitalSignsMonitoring event,
    Emitter<DeviceState> emit,
  ) async {
    // Stream cancellation is handled automatically by emit.forEach
  }

  Future<void> _onUpdateDeviceSettings(
    UpdateDeviceSettings event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.updateDeviceSettings(
      event.deviceId,
      event.settings,
    );
    
    result.fold(
      (failure) => emit(DeviceError(
        message: failure.message,
        device: _currentDevice,
      )),
      (_) {
        if (_currentDevice != null) {
          emit(DeviceSettingsUpdated(
            device: _currentDevice!,
            settings: event.settings,
          ));
        }
      },
    );
  }

  Future<void> _onLoadDeviceSettings(
    LoadDeviceSettings event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.getDeviceSettings(event.deviceId);
    
    result.fold(
      (failure) => emit(DeviceError(
        message: failure.message,
        device: _currentDevice,
      )),
      (settings) {
        if (_currentDevice != null) {
          emit(DeviceSettingsLoaded(
            device: _currentDevice!,
            settings: settings,
          ));
        }
      },
    );
  }

  Future<void> _onLoadVitalSignsHistory(
    LoadVitalSignsHistory event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.getVitalSignsHistory(
      event.deviceId,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    
    result.fold(
      (failure) => emit(DeviceError(
        message: failure.message,
        device: _currentDevice,
      )),
      (history) {
        _vitalSignsHistory = history;
        if (_currentDevice != null) {
          emit(DeviceHistoryLoaded(
            device: _currentDevice!,
            history: history,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateFirmware(
    UpdateFirmware event,
    Emitter<DeviceState> emit,
  ) async {
    if (_currentDevice != null) {
      emit(DeviceFirmwareUpdating(
        device: _currentDevice!,
        progress: 0.0,
      ));
    }
    
    final result = await repository.updateFirmware(
      event.deviceId,
      event.firmwareData,
    );
    
    result.fold(
      (failure) => emit(DeviceError(
        message: failure.message,
        device: _currentDevice,
      )),
      (_) {
        if (_currentDevice != null) {
          emit(DeviceFirmwareUpdated(_currentDevice!));
        }
      },
    );
  }

  Future<void> _onLoadConnectedDevice(
    LoadConnectedDevice event,
    Emitter<DeviceState> emit,
  ) async {
    final result = await repository.getConnectedDevice();
    
    result.fold(
      (failure) => emit(DeviceError(message: failure.message)),
      (device) {
        if (device != null) {
          _currentDevice = device;
          emit(DeviceConnected(device: device));
          
          // Start monitoring vital signs
          add(StartVitalSignsMonitoring(device.id));
          
          // Load settings
          add(LoadDeviceSettings(device.id));
        } else {
          emit(const DeviceDisconnected());
        }
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}
