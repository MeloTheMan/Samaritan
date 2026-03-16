import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/device_bloc.dart';
import '../bloc/device_event.dart';
import '../bloc/device_state.dart';
import '../../domain/entities/wearable_device.dart';
import 'demo_health_dashboard_screen.dart';
import '../../../../core/services/demo_service.dart';
import '../../../../core/di/injection.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  @override
  void initState() {
    super.initState();
    // Check if there's already a connected device
    context.read<DeviceBloc>().add(const LoadConnectedDevice());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bracelet'),
        elevation: 0,
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) {
          if (state is DeviceConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Device connected successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is DeviceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DeviceConnected) {
            return _buildConnectedView(context, state.device);
          } else if (state is DeviceScanning) {
            return _buildScanningView(context, state.devices);
          } else if (state is DeviceScanComplete) {
            return _buildScanCompleteView(context, state.devices);
          } else if (state is DeviceConnecting) {
            return _buildConnectingView(context);
          } else if (state is DeviceError) {
            return _buildErrorView(context, state.message);
          }
          
          return _buildInitialView(context);
        },
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch,
            size: 100,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No device connected',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Scan for nearby Samaritan bracelets to connect',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DeviceBloc>().add(const StartDeviceScan());
            },
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(indent: 40, endIndent: 40),
          const SizedBox(height: 8),
          Text(
            'Ou testez sans bracelet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _startDemoMode(context);
            },
            icon: const Icon(Icons.science),
            label: const Text('Mode Démo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _startDemoMode(BuildContext context) {
    final demoService = getIt<DemoService>();
    final demoDevice = demoService.generateDemoDevice();
    
    // Naviguer directement vers le dashboard de démo
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DemoHealthDashboardScreen(
          demoDevice: demoDevice,
        ),
      ),
    );
  }

  Widget _buildScanningView(BuildContext context, List<WearableDevice> devices) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Scanning for devices...'),
              ),
              TextButton(
                onPressed: () {
                  context.read<DeviceBloc>().add(const StopDeviceScan());
                },
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
        Expanded(
          child: devices.isEmpty
              ? const Center(
                  child: Text(
                    'No devices found yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return _buildDeviceListItem(context, devices[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScanCompleteView(BuildContext context, List<WearableDevice> devices) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Found ${devices.length} device(s)'),
              ),
              TextButton(
                onPressed: () {
                  context.read<DeviceBloc>().add(const StartDeviceScan());
                },
                child: const Text('Scan Again'),
              ),
            ],
          ),
        ),
        Expanded(
          child: devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No devices found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DeviceBloc>().add(const StartDeviceScan());
                        },
                        child: const Text('Scan Again'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return _buildDeviceListItem(context, devices[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceListItem(BuildContext context, WearableDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.watch),
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.id.substring(0, 8)}...'),
            Text('Signal: ${device.signalQuality}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            context.read<DeviceBloc>().add(ConnectToDevice(device.id));
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildConnectingView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Connecting to device...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, WearableDevice device) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Device Connected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            device.name,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection Error',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceBloc>().add(const StartDeviceScan());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
