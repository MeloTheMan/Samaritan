import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../../take_charge/presentation/screens/take_charge_screen.dart';
import '../../../take_charge/presentation/bloc/intervention_bloc.dart';
import '../../../take_charge/presentation/bloc/intervention_event.dart';
import '../../../device/data/services/bluetooth_service.dart';
import '../../../../core/di/injection.dart';

class NavigationScreen extends StatefulWidget {
  final EmergencyAlert alert;

  const NavigationScreen({
    super.key,
    required this.alert,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final BluetoothService _bluetoothService = getIt<BluetoothService>();
  StreamSubscription? _scanSubscription;
  int _currentRssi = -100;
  double _estimatedDistance = 0;
  String _proximityLevel = 'Recherche...';
  Color _proximityColor = Colors.grey;
  
  @override
  void initState() {
    super.initState();
    _startRssiTracking();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void _startRssiTracking() {
    // Scanner en continu pour obtenir le RSSI
    _scanSubscription = _bluetoothService.scanForDevices().listen(
      (scanResults) {
        // Ignorer les résultats vides
        if (scanResults.isEmpty) return;
        
        // Chercher le bracelet de la victime
        try {
          final victimResult = scanResults.firstWhere(
            (result) => result.device.remoteId.toString() == widget.alert.victimDeviceId,
            orElse: () => scanResults.first, // Utiliser le premier appareil trouvé par défaut
          );
          
          if (mounted) {
            setState(() {
              _currentRssi = victimResult.rssi;
              _estimatedDistance = _calculateDistance(_currentRssi);
              _updateProximityLevel(_estimatedDistance);
            });
          }
        } catch (e) {
          // Ignorer silencieusement les erreurs de scan
          print('⚠️ RSSI tracking error: $e');
        }
      },
      onError: (error) {
        print('⚠️ Scan stream error: $error');
      },
    );
  }

  double _calculateDistance(int rssi) {
    // Formule de path loss pour estimer la distance
    // d = 10 ^ ((TxPower - RSSI) / (10 * n))
    // TxPower typique pour BLE = -59 dBm à 1m
    // n = facteur d'atténuation (2-4, on utilise 2.5 pour intérieur)
    const txPower = -59;
    const n = 2.5;
    
    if (rssi == 0) return 0;
    
    final distance = math.pow(10, (txPower - rssi) / (10 * n));
    return distance.toDouble();
  }

  void _updateProximityLevel(double distance) {
    if (distance < 2) {
      _proximityLevel = 'TRÈS PROCHE !';
      _proximityColor = Colors.green;
    } else if (distance < 5) {
      _proximityLevel = 'Proche';
      _proximityColor = Colors.lightGreen;
    } else if (distance < 10) {
      _proximityLevel = 'Moyen';
      _proximityColor = Colors.orange;
    } else if (distance < 20) {
      _proximityLevel = 'Éloigné';
      _proximityColor = Colors.deepOrange;
    } else {
      _proximityLevel = 'Très éloigné';
      _proximityColor = Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation vers la victime'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Statut de l'alerte
            if (widget.alert.status == AlertStatus.beingHandled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cette victime est déjà prise en charge par un autre bénévole',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Indicateur de proximité RSSI
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Indicateur visuel de proximité
                    _buildProximityIndicator(),
                    
                    const SizedBox(height: 32),

                    // Distance estimée
                    Text(
                      '${_estimatedDistance.toStringAsFixed(1)} m',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _proximityColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distance estimée (RSSI: $_currentRssi dBm)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Niveau de proximité
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: _proximityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _proximityColor, width: 2),
                      ),
                      child: Text(
                        _proximityLevel,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _proximityColor,
                            ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Instructions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Déplacez-vous pour améliorer le signal',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton de prise en charge
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.alert.status != AlertStatus.beingHandled)
                    ElevatedButton.icon(
                      onPressed: _estimatedDistance < 5 ? () {
                        // Naviguer vers l'écran de prise en charge
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => getIt<InterventionBloc>()
                                ..add(
                                  InitiateTakeCharge(
                                    victimDeviceId: widget.alert.victimDeviceId,
                                    volunteerId: 'current_user_id',
                                    alertId: widget.alert.alertId,
                                  ),
                                ),
                              child: const TakeChargeScreen(),
                            ),
                          ),
                        );
                      } : null,
                      icon: const Icon(Icons.medical_services, size: 28),
                      label: Text(
                        _estimatedDistance < 5 
                          ? 'PRENDRE EN CHARGE'
                          : 'Rapprochez-vous (< 5m)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        minimumSize: const Size(double.infinity, 60),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximityIndicator() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _proximityColor.withOpacity(0.8),
            _proximityColor.withOpacity(0.4),
            _proximityColor.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _proximityColor.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _proximityColor,
          ),
          child: Icon(
            Icons.person_pin_circle,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}