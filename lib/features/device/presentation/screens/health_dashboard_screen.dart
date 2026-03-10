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

  @override
  void initState() {
    super.initState();
    // Load connected device on init
    context.read<DeviceBloc>().add(const LoadConnectedDevice());
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
            const SizedBox(height: 24),
            
            // Vital signs cards
            const Text(
              'Current Vital Signs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${currentVitalSigns.temperature.toStringAsFixed(1)}°C',
                    isNormal: currentVitalSigns.temperature >= 36.0 && 
                             currentVitalSigns.temperature <= 37.5,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: '${currentVitalSigns.heartRate} BPM',
                    isNormal: currentVitalSigns.heartRate >= 60 && 
                             currentVitalSigns.heartRate <= 100,
                    color: Colors.red,
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
                    label: 'Oxygen',
                    value: '${currentVitalSigns.oxygenSaturation}%',
                    isNormal: currentVitalSigns.oxygenSaturation >= 95,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VitalSignCard(
                    icon: Icons.warning,
                    label: 'Fall Detection',
                    value: currentVitalSigns.fallDetected ? 'Alert' : 'Normal',
                    isNormal: !currentVitalSigns.fallDetected,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            if (history.isNotEmpty) ...[
              const SizedBox(height: 32),
              
              // Period selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '24h', label: Text('24h')),
                      ButtonSegment(value: '7d', label: Text('7d')),
                      ButtonSegment(value: '30d', label: Text('30d')),
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
              
              // Charts
              _buildChart(
                context,
                'Heart Rate',
                history,
                (vs) => vs.heartRate.toDouble(),
                Colors.red,
              ),
              const SizedBox(height: 24),
              _buildChart(
                context,
                'Temperature',
                history,
                (vs) => vs.temperature,
                Colors.orange,
              ),
              const SizedBox(height: 24),
              _buildChart(
                context,
                'Oxygen Saturation',
                history,
                (vs) => vs.oxygenSaturation.toDouble(),
                Colors.blue,
              ),
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
    String statusText;
    IconData statusIcon;
    
    if (isCritical) {
      statusColor = Colors.red;
      statusText = 'Critical - Seek immediate help';
      statusIcon = Icons.error;
    } else if (!isNormal) {
      statusColor = Colors.orange;
      statusText = 'Abnormal - Monitor closely';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'All vitals normal';
      statusIcon = Icons.check_circle;
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
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${_formatTime(vitalSigns.timestamp)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    String title,
    List<VitalSigns> history,
    double Function(VitalSigns) getValue,
    Color color,
  ) {
    final filteredHistory = _filterHistoryByPeriod(history);
    
    if (filteredHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final spots = filteredHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), getValue(entry.value));
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
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

  List<VitalSigns> _filterHistoryByPeriod(List<VitalSigns> history) {
    final now = DateTime.now();
    Duration period;
    
    switch (_selectedPeriod) {
      case '24h':
        period = const Duration(hours: 24);
        break;
      case '7d':
        period = const Duration(days: 7);
        break;
      case '30d':
        period = const Duration(days: 30);
        break;
      default:
        period = const Duration(hours: 24);
    }
    
    final cutoff = now.subtract(period);
    return history.where((vs) => vs.timestamp.isAfter(cutoff)).toList();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildWaitingForData(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Waiting for vital signs data...',
            style: TextStyle(fontSize: 16),
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
            'Connect your bracelet to view health data',
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

  Widget _buildLoadingView(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 100, color: Colors.red),
          const SizedBox(height: 24),
          const Text(
            'Error',
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
              context.read<DeviceBloc>().add(const LoadConnectedDevice());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
