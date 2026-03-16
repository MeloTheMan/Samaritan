import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bloc/device_bloc.dart';
import '../bloc/device_event.dart';
import '../bloc/device_state.dart';
import '../../domain/entities/vital_signs.dart';
import '../widgets/vital_sign_card.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  String _selectedPeriod = '24h';
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ne charger que si pas déjà connecté
    final state = context.read<DeviceBloc>().state;
    if (state is! DeviceConnected && state is! DeviceVitalSignsUpdated) {
      context.read<DeviceBloc>().add(const LoadConnectedDevice());
    }
    _hasInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/device-settings');
            },
          ),
        ],
      ),
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceVitalSignsUpdated) {
            return _buildDashboard(context, state.vitalSigns, state.history);
          } else if (state is DeviceConnected) {
            if (state.currentVitalSigns != null) {
              return _buildDashboard(context, state.currentVitalSigns!, []);
            }
            return _buildWaitingForData(context);
          } else if (state is DeviceDisconnected || state is DeviceInitial) {
            return _buildNoDeviceView(context);
          } else if (state is DeviceError) {
            return _buildErrorView(context, state.message);
          }
          
          return _buildLoadingView(context);
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    VitalSigns currentVitalSigns,
    List<VitalSigns> history,
  ) {
    final sensorStatus = currentVitalSigns.sensorStatus;
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeviceBloc>().add(const LoadConnectedDevice());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            _buildStatusCard(currentVitalSigns),
            const SizedBox(height: 16),
            
            // Sensor status indicator
            _buildSensorStatusCard(sensorStatus),
            const SizedBox(height: 24),
            
            // Vital signs cards - Body measurements
            const Text(
              'Signes Vitaux Corporels',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.thermostat,
                    label: 'Température Corporelle',
                    value: '${currentVitalSigns.temperature.toStringAsFixed(1)}°C',
                    isNormal: currentVitalSigns.temperature >= 36.0 && 
                             currentVitalSigns.temperature <= 37.5,
                    color: Colors.orange,
                    isAvailable: sensorStatus.max30102Available,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.favorite,
                    label: 'Fréquence Cardiaque',
                    value: '${currentVitalSigns.heartRate} BPM',
                    isNormal: currentVitalSigns.heartRate >= 60 && 
                             currentVitalSigns.heartRate <= 100,
                    color: Colors.red,
                    isAvailable: sensorStatus.max30102Available,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.air,
                    label: 'Saturation Oxygène',
                    value: '${currentVitalSigns.oxygenSaturation}%',
                    isNormal: currentVitalSigns.oxygenSaturation >= 95,
                    color: Colors.blue,
                    isAvailable: sensorStatus.max30102Available,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignCard(
                    icon: currentVitalSigns.fallDetected 
                        ? Icons.warning 
                        : Icons.accessibility_new,
                    label: 'Détection de Chute',
                    value: currentVitalSigns.fallDetected ? 'CHUTE!' : 'Normal',
                    isNormal: !currentVitalSigns.fallDetected,
                    color: currentVitalSigns.fallDetected 
                        ? Colors.red 
                        : Colors.green,
                    isAvailable: sensorStatus.mpu6050Available,
                  ),
                ),
              ],
            ),
            
            // Ambient measurements
            const SizedBox(height: 24),
            const Text(
              'Conditions Ambiantes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.wb_sunny,
                    label: 'Température Ambiante',
                    value: currentVitalSigns.ambientTemperature != null
                        ? '${currentVitalSigns.ambientTemperature!.toStringAsFixed(1)}°C'
                        : 'N/A',
                    isNormal: currentVitalSigns.ambientTemperature != null &&
                             currentVitalSigns.ambientTemperature! >= 18.0 &&
                             currentVitalSigns.ambientTemperature! <= 26.0,
                    color: Colors.amber,
                    isAvailable: sensorStatus.dht11Available,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.water_drop,
                    label: 'Humidité',
                    value: currentVitalSigns.humidity != null
                        ? '${currentVitalSigns.humidity!.toStringAsFixed(0)}%'
                        : 'N/A',
                    isNormal: currentVitalSigns.humidity != null &&
                             currentVitalSigns.humidity! >= 30.0 &&
                             currentVitalSigns.humidity! <= 60.0,
                    color: Colors.cyan,
                    isAvailable: sensorStatus.dht11Available,
                  ),
                ),
              ],
            ),
            
            // Movement indicators
            if (sensorStatus.mpu6050Available) ...[
              const SizedBox(height: 24),
              _buildMovementCard(currentVitalSigns),
            ],
            
            // Historical data chart
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildHistoricalChart(history),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(VitalSigns vitalSigns) {
    final isNormal = vitalSigns.isNormal;
    final isCritical = vitalSigns.isCritical;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isCritical) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'CRITIQUE';
    } else if (!isNormal) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'ATTENTION';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'NORMAL';
    }
    
    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'État de Santé',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              vitalSigns.timestamp.toString().substring(11, 16),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusCard(SensorStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.allAvailable 
                      ? Icons.sensors 
                      : Icons.sensors_off,
                  color: status.allAvailable 
                      ? Colors.green 
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'État des Capteurs',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${status.availableCount}/3',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSensorIndicator(
                  'MAX30102',
                  'HR/SpO2/Temp',
                  status.max30102Available,
                ),
                _buildSensorIndicator(
                  'MPU6050',
                  'Chute',
                  status.mpu6050Available,
                ),
                _buildSensorIndicator(
                  'DHT11',
                  'Ambiant',
                  status.dht11Available,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(String name, String description, bool available) {
    return Column(
      children: [
        Icon(
          available ? Icons.check_circle : Icons.cancel,
          color: available ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMovementCard(VitalSigns vitalSigns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détection de Mouvement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMovementIndicator(
                    'Chute Détectée',
                    vitalSigns.fallDetected,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMovementIndicator(
                    'Mouvement Brusque',
                    vitalSigns.suddenMovement,
                    Icons.directions_run,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementIndicator(String label, bool detected, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: detected 
            ? Colors.red.withOpacity(0.1) 
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: detected ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  detected ? 'OUI' : 'NON',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: detected ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalChart(List<VitalSigns> history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Historical Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '1h', label: Text('1h')),
                    ButtonSegment(value: '24h', label: Text('24h')),
                    ButtonSegment(value: '7d', label: Text('7d')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(history),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<VitalSigns> history) {
    return List.generate(
      history.length,
      (index) => FlSpot(
        index.toDouble(),
        history[index].heartRate.toDouble(),
      ),
    );
  }

  Widget _buildWaitingForData(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Waiting for vital signs data...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDeviceView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No device connected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/device-connection');
            },
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Connect Device'),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceBloc>().add(const LoadConnectedDevice());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
