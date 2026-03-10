import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../../domain/entities/take_charge_session.dart';
import '../../../device/domain/repositories/device_repository.dart';
import '../../../device/domain/entities/vital_signs.dart';
import '../../../../core/error/failures.dart';
import 'intervention_event.dart';
import 'intervention_state.dart';

@injectable
class InterventionBloc extends Bloc<InterventionEvent, InterventionState> {
  final InterventionRepository repository;
  final DeviceRepository deviceRepository;
  
  TakeChargeSession? _currentSession;
  StreamSubscription<Either<Failure, VitalSigns>>? _vitalSignsSubscription;

  InterventionBloc({
    required this.repository,
    required this.deviceRepository,
  }) : super(const InterventionInitial()) {
    on<InitiateTakeCharge>(_onInitiateTakeCharge);
    on<LoadActiveSession>(_onLoadActiveSession);
    on<AddCareAction>(_onAddCareAction);
    on<UpdateVitalSigns>(_onUpdateVitalSigns);
    on<EndIntervention>(_onEndIntervention);
    on<LoadInterventionHistory>(_onLoadInterventionHistory);
    on<RefineWithAI>(_onRefineWithAI);
  }

  Future<void> _onInitiateTakeCharge(
    InitiateTakeCharge event,
    Emitter<InterventionState> emit,
  ) async {
    emit(InterventionConnecting(victimDeviceId: event.victimDeviceId));
    
    final result = await repository.createSession(
      victimDeviceId: event.victimDeviceId,
      volunteerId: event.volunteerId,
      alertId: event.alertId,
    );
    
    await result.fold(
      (failure) async => emit(InterventionError(
        message: failure.message,
        session: _currentSession,
      )),
      (session) async {
        _currentSession = session;
        
        // Scanner et se connecter au bracelet "Samaritan Test"
        try {
          print('🔍 Scanning for Samaritan bracelet...');
          
          // Scanner pendant 5 secondes pour trouver le bracelet
          String? braceletDeviceId;
          
          await for (final result in deviceRepository.scanForDevices(timeout: const Duration(seconds: 5))) {
            await result.fold(
              (failure) async {
                print('⚠️ Scan error: ${failure.message}');
              },
              (devices) async {
                // Chercher un device nommé "Samaritan Test"
                final samaritanDevice = devices.where((d) => 
                  d.name.toLowerCase().contains('samaritan')
                ).firstOrNull;
                
                if (samaritanDevice != null) {
                  braceletDeviceId = samaritanDevice.id;
                  print('✓ Found Samaritan bracelet: ${samaritanDevice.name} (${samaritanDevice.id})');
                }
              },
            );
            
            // Si on a trouvé le bracelet, arrêter le scan
            if (braceletDeviceId != null) break;
          }
          
          // Arrêter le scan
          await deviceRepository.stopScan();
          
          if (braceletDeviceId == null) {
            print('❌ Samaritan bracelet not found');
            emit(InterventionError(
              message: 'Bracelet Samaritan non trouvé. Assurez-vous qu\'il est allumé et à proximité.',
              session: session,
            ));
            return;
          }
          
          // Se connecter au bracelet trouvé
          print('🔗 Connecting to bracelet...');
          final connectResult = await deviceRepository.connectToDevice(braceletDeviceId!);
          
          await connectResult.fold(
            (failure) async {
              emit(InterventionError(
                message: 'Erreur de connexion au bracelet: ${failure.message}',
                session: session,
              ));
            },
            (device) async {
              print('✓ Connected to bracelet');
              
              // Émettre l'état actif
              emit(InterventionActive(session: session));
              
              // Écouter les mises à jour des signes vitaux en arrière-plan
              final vitalSignsStream = deviceRepository.getVitalSignsStream(braceletDeviceId!);
              
              // Utiliser emit.forEach pour gérer le stream correctement
              await emit.forEach<Either<Failure, VitalSigns>>(
                vitalSignsStream,
                onData: (result) {
                  return result.fold(
                    (failure) {
                      print('⚠️ Vital signs error: ${failure.message}');
                      return state; // Retourner l'état actuel sans changement
                    },
                    (vitalSigns) {
                      print('📊 Vital signs updated: ${vitalSigns.temperature}°C, ${vitalSigns.heartRate} BPM');
                      
                      // Mettre à jour la session localement avec les nouveaux signes vitaux
                      if (_currentSession != null) {
                        final updatedHistory = List<VitalSigns>.from(_currentSession!.vitalSignsHistory)
                          ..add(vitalSigns);
                        
                        final updatedSession = _currentSession!.copyWith(
                          vitalSignsHistory: updatedHistory,
                        );
                        _currentSession = updatedSession;
                        
                        return InterventionActive(session: updatedSession);
                      }
                      return state;
                    },
                  );
                },
              );
            },
          );
        } catch (e) {
          print('❌ Connection error: ${e.toString()}');
          emit(InterventionError(
            message: 'Erreur de connexion au bracelet: ${e.toString()}',
            session: session,
          ));
        }
      },
    );
  }

  Future<void> _onLoadActiveSession(
    LoadActiveSession event,
    Emitter<InterventionState> emit,
  ) async {
    final result = await repository.getActiveSession();
    
    result.fold(
      (failure) => emit(InterventionError(message: failure.message)),
      (session) {
        if (session != null) {
          _currentSession = session;
          emit(InterventionActive(session: session));
        } else {
          emit(const InterventionInitial());
        }
      },
    );
  }

  Future<void> _onAddCareAction(
    AddCareAction event,
    Emitter<InterventionState> emit,
  ) async {
    if (_currentSession == null) {
      emit(const InterventionError(message: 'Aucune session active'));
      return;
    }

    final result = await repository.addCareAction(
      _currentSession!.sessionId,
      event.action,
    );
    
    result.fold(
      (failure) => emit(InterventionError(
        message: failure.message,
        session: _currentSession,
      )),
      (_) async {
        // Recharger la session mise à jour
        final sessionResult = await repository.getSession(_currentSession!.sessionId);
        sessionResult.fold(
          (failure) => emit(InterventionError(
            message: failure.message,
            session: _currentSession,
          )),
          (updatedSession) {
            _currentSession = updatedSession;
            emit(InterventionCareActionAdded(session: updatedSession));
          },
        );
      },
    );
  }

  Future<void> _onUpdateVitalSigns(
    UpdateVitalSigns event,
    Emitter<InterventionState> emit,
  ) async {
    if (_currentSession == null) {
      emit(const InterventionError(message: 'Aucune session active'));
      return;
    }

    final result = await repository.addVitalSigns(
      _currentSession!.sessionId,
      event.vitalSigns,
    );
    
    result.fold(
      (failure) => emit(InterventionError(
        message: failure.message,
        session: _currentSession,
      )),
      (_) async {
        // Recharger la session mise à jour
        final sessionResult = await repository.getSession(_currentSession!.sessionId);
        sessionResult.fold(
          (failure) => emit(InterventionError(
            message: failure.message,
            session: _currentSession,
          )),
          (updatedSession) {
            _currentSession = updatedSession;
            emit(InterventionVitalSignsUpdated(session: updatedSession));
          },
        );
      },
    );
  }

  Future<void> _onEndIntervention(
    EndIntervention event,
    Emitter<InterventionState> emit,
  ) async {
    if (_currentSession == null) {
      emit(const InterventionError(message: 'Aucune session active'));
      return;
    }

    emit(InterventionEnding(session: _currentSession!));

    final result = await repository.endSession(
      _currentSession!.sessionId,
      event.outcome,
    );
    
    result.fold(
      (failure) => emit(InterventionError(
        message: failure.message,
        session: _currentSession,
      )),
      (_) async {
        // Recharger la session terminée
        final sessionResult = await repository.getSession(_currentSession!.sessionId);
        sessionResult.fold(
          (failure) => emit(InterventionError(
            message: failure.message,
            session: _currentSession,
          )),
          (completedSession) {
            _currentSession = null;
            emit(InterventionCompleted(session: completedSession));
          },
        );
      },
    );
  }

  Future<void> _onLoadInterventionHistory(
    LoadInterventionHistory event,
    Emitter<InterventionState> emit,
  ) async {
    final result = await repository.getSessionHistory(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    
    result.fold(
      (failure) => emit(InterventionError(
        message: failure.message,
        session: _currentSession,
      )),
      (history) => emit(InterventionHistoryLoaded(history: history)),
    );
  }

  Future<void> _onRefineWithAI(
    RefineWithAI event,
    Emitter<InterventionState> emit,
  ) async {
    if (_currentSession == null) {
      emit(const InterventionError(message: 'Aucune session active'));
      return;
    }

    // TODO: Intégrer avec le module AI Assistant pour affiner les recommandations
    // Pour l'instant, on garde la session telle quelle
    emit(InterventionActive(session: _currentSession!));
  }

  @override
  Future<void> close() async {
    await _vitalSignsSubscription?.cancel();
    if (_currentSession != null) {
      await deviceRepository.disconnectFromDevice(_currentSession!.victimDeviceId);
    }
    return super.close();
  }
}
