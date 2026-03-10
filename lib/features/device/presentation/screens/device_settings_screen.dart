import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_bloc.dart';
import '../bloc/device_event.dart';
import '../bloc/device_state.dart';
import '../../domain/entities/device_settings.dart';
import '../../domain/entities/wearable_device.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  late DeviceSettings _currentSettings;
  WearableDevice? _currentDevice;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentSettings = DeviceSettings.defaultSettings();
    context.read<DeviceBloc>().add(const LoadConnectedDevice());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) {
          if (state is DeviceSettingsLoaded) {
            setState(() {
              _currentSettings = state.settings;
              _currentDevice = state.device;
              _hasChanges = false;
            });
          } else if (state is DeviceSettingsUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _currentSettings = state.settings;
              _hasChanges = false;
            });
          } else if (state is DeviceConnected) {
            setState(() {
              _currentDevice = state.device;
            });
            if (state.settings != null) {
              setState(() {
                _currentSettings = state.settings!;
              });
            } else {
              context.read<DeviceBloc>().add(LoadDeviceSettings(state.device.id));
            }
          } else if (state is DeviceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DeviceFirmwareUpdating) {
            // Show progress
          } else if (state is DeviceFirmwareUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firmware updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_currentDevice == null) {
            return _buildNoDeviceView(context);
          }

          if (state is DeviceFirmwareUpdating) {
            return _buildFirmwareUpdatingView(context, state.progress);
          }

          return _buildSettingsView(context);
        },
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device info card
          _buildDeviceInfoCard(),
          const SizedBox(height: 24),

          // Vital signs thresholds
          const Text(
            'Vital Signs Thresholds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildThresholdSection(),
          const SizedBox(height: 24),

          // Monitoring settings
          const Text(
            'Monitoring Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMonitoringSection(),
          const SizedBox(height: 24),

          // Alert settings
          const Text(
            'Alert Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAlertSection(),
          const SizedBox(height: 24),

          // Firmware update
          const Text(
            'Firmware',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFirmwareSection(),
          const SizedBox(height: 24),

          // Disconnect button
          _buildDisconnectButton(),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    if (_currentDevice == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.watch, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDevice!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_currentDevice!.id.substring(0, 8)}...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Battery',
                  '${_currentDevice!.batteryLevel}%',
                  Icons.battery_full,
                ),
                _buildInfoItem(
                  'Signal',
                  _currentDevice!.signalQuality,
                  Icons.signal_cellular_alt,
                ),
                _buildInfoItem(
                  'Firmware',
                  _currentDevice!.firmwareVersion,
                  Icons.system_update,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildThresholdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRangeSlider(
              'Temperature (°C)',
              _currentSettings.temperatureThresholdMin,
              _currentSettings.temperatureThresholdMax,
              30.0,
              42.0,
              (min, max) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    temperatureThresholdMin: min,
                    temperatureThresholdMax: max,
                  );
                  _hasChanges = true;
                });
              },
            ),
            const Divider(height: 32),
            _buildRangeSlider(
              'Heart Rate (BPM)',
              _currentSettings.heartRateThresholdMin.toDouble(),
              _currentSettings.heartRateThresholdMax.toDouble(),
              40.0,
              180.0,
              (min, max) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    heartRateThresholdMin: min.round(),
                    heartRateThresholdMax: max.round(),
                  );
                  _hasChanges = true;
                });
              },
            ),
            const Divider(height: 32),
            _buildSlider(
              'Oxygen Saturation Min (%)',
              _currentSettings.oxygenSaturationThresholdMin.toDouble(),
              80.0,
              100.0,
              (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    oxygenSaturationThresholdMin: value.round(),
                  );
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Measurement Frequency'),
                DropdownButton<int>(
                  value: _currentSettings.measurementFrequency,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 second')),
                    DropdownMenuItem(value: 5, child: Text('5 seconds')),
                    DropdownMenuItem(value: 10, child: Text('10 seconds')),
                    DropdownMenuItem(value: 30, child: Text('30 seconds')),
                    DropdownMenuItem(value: 60, child: Text('1 minute')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currentSettings = _currentSettings.copyWith(
                          measurementFrequency: value,
                        );
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Fall Detection'),
              subtitle: const Text('Alert when a fall is detected'),
              value: _currentSettings.fallDetectionEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    fallDetectionEnabled: value,
                  );
                  _hasChanges = true;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Alerts Enabled'),
              subtitle: const Text('Receive alerts for abnormal vitals'),
              value: _currentSettings.alertsEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    alertsEnabled: value,
                  );
                  _hasChanges = true;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate on alerts'),
              value: _currentSettings.vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    vibrationEnabled: value,
                  );
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmwareSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Version',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentDevice?.firmwareVersion ?? 'Unknown',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _checkForFirmwareUpdate,
                  icon: const Icon(Icons.system_update),
                  label: const Text('Check for Updates'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _disconnectDevice,
        icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
        label: const Text(
          'Disconnect Device',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRangeSlider(
    String label,
    double min,
    double max,
    double rangeMin,
    double rangeMax,
    Function(double, double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        RangeSlider(
          values: RangeValues(min, max),
          min: rangeMin,
          max: rangeMax,
          divisions: ((rangeMax - rangeMin) * 2).round(),
          onChanged: (values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(color: Colors.grey[600]),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNoDeviceView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch_off,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No device connected',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect your bracelet to configure settings',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/device-connection');
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text('Connect Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmwareUpdatingView(BuildContext context, double progress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Updating Firmware...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(value: progress),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Please keep the device nearby',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    if (_currentDevice != null) {
      context.read<DeviceBloc>().add(
            UpdateDeviceSettings(
              deviceId: _currentDevice!.id,
              settings: _currentSettings,
            ),
          );
    }
  }

  void _checkForFirmwareUpdate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check for Updates'),
        content: const Text(
          'This feature would check for firmware updates from the server. '
          'For this demo, no updates are available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _disconnectDevice() {
    if (_currentDevice != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disconnect Device'),
          content: const Text(
            'Are you sure you want to disconnect from this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<DeviceBloc>().add(
                      DisconnectFromDevice(_currentDevice!.id),
                    );
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }
}