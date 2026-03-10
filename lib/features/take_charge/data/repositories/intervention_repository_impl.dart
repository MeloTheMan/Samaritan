import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/take_charge_session.dart';
import '../../domain/entities/care_action.dart';
import '../../domain/entities/intervention_outcome.dart';
import '../../domain/entities/prognosis.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../../domain/services/vital_signs_analyzer.dart';
import '../../../device/domain/entities/vital_signs.dart';

@Injectable(as: InterventionRepository)
class InterventionRepositoryImpl implements InterventionRepository {
  final VitalSignsAnalyzer _vitalSignsAnalyzer;
  static const String _sessionBoxName = 'intervention_sessions';
  
  Box<TakeChargeSession>? _sessionBox;
  final _uuid = const Uuid();

  InterventionRepositoryImpl(this._vitalSignsAnalyzer);

  Future<Box<TakeChargeSession>> get _box async {
    if (_sessionBox == null || !_sessionBox!.isOpen) {
      _sessionBox = await Hive.openBox<TakeChargeSession>(_sessionBoxName);
    }
    return _sessionBox!;
  }

  @override
  Future<Either<Failure, TakeChargeSession>> createSession({
    required String victimDeviceId,
    required String volunteerId,
    required String alertId,
  }) async {
    try {
      // Vérifier qu'il n'y a pas déjà une session active
      final activeSession = await getActiveSession();
      if (activeSession.isRight()) {
        final session = activeSession.getOrElse(() => null);
        if (session != null) {
          // Fermer automatiquement la session précédente
          await endSession(
            session.sessionId,
            InterventionOutcome(
              type: OutcomeType.stable,
              notes: 'Session fermée automatiquement pour nouvelle intervention',
              recordedAt: DateTime.now(),
            ),
          );
        }
      }

      final sessionId = _uuid.v4();
      
      // Créer un pronostic initial avec des valeurs par défaut
      // (sera mis à jour dès réception des premiers signes vitaux)
      final initialPrognosis = Prognosis(
        level: PrognosisLevel.moderate,
        description: 'En attente des signes vitaux...',
        criticalFactors: const [],
        initialRecommendations: const [
          'Connexion au bracelet en cours...',
          'Vérifier la conscience de la victime',
          'Rassurer la victime',
        ],
        analyzedAt: DateTime.now(),
      );

      final session = TakeChargeSession(
        sessionId: sessionId,
        victimDeviceId: victimDeviceId,
        volunteerId: volunteerId,
        startTime: DateTime.now(),
        initialPrognosis: initialPrognosis,
        vitalSignsHistory: const [],
        actionsPerformed: const [],
        alertId: alertId,
      );

      final box = await _box;
      await box.put(sessionId, session);

      return Right(session);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la création de la session: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TakeChargeSession?>> getActiveSession() async {
    try {
      final box = await _box;
      final sessions = box.values.where((s) => s.isActive).toList();
      
      if (sessions.isEmpty) {
        return const Right(null);
      }
      
      // Retourner la session la plus récente si plusieurs actives
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return Right(sessions.first);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la récupération de la session: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addCareAction(
    String sessionId,
    CareAction action,
  ) async {
    try {
      final box = await _box;
      final session = box.get(sessionId);
      
      if (session == null) {
        return Left(CacheFailure('Session non trouvée'));
      }

      final updatedActions = List<CareAction>.from(session.actionsPerformed)
        ..add(action);

      final updatedSession = session.copyWith(
        actionsPerformed: updatedActions,
      );

      await box.put(sessionId, updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de l\'ajout de l\'action: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addVitalSigns(
    String sessionId,
    VitalSigns vitalSigns,
  ) async {
    try {
      final box = await _box;
      final session = box.get(sessionId);
      
      if (session == null) {
        return Left(CacheFailure('Session non trouvée'));
      }

      final updatedHistory = List<VitalSigns>.from(session.vitalSignsHistory)
        ..add(vitalSigns);

      // Mettre à jour le pronostic si c'est le premier relevé
      var updatedSession = session.copyWith(
        vitalSignsHistory: updatedHistory,
      );

      if (session.vitalSignsHistory.isEmpty) {
        final prognosis = _vitalSignsAnalyzer.analyzeVitalSigns(vitalSigns);
        updatedSession = updatedSession.copyWith(
          initialPrognosis: prognosis,
        );
      }

      await box.put(sessionId, updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de l\'ajout des signes vitaux: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> endSession(
    String sessionId,
    InterventionOutcome outcome,
  ) async {
    try {
      final box = await _box;
      final session = box.get(sessionId);
      
      if (session == null) {
        return Left(CacheFailure('Session non trouvée'));
      }

      final updatedSession = session.copyWith(
        endTime: DateTime.now(),
        outcome: outcome,
      );

      await box.put(sessionId, updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la fin de session: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TakeChargeSession>> getSession(String sessionId) async {
    try {
      final box = await _box;
      final session = box.get(sessionId);
      
      if (session == null) {
        return Left(CacheFailure('Session non trouvée'));
      }

      return Right(session);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la récupération: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TakeChargeSession>>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final box = await _box;
      var sessions = box.values.toList();
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate)).toList();
      }
      
      // Trier par date (plus récent en premier)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la récupération de l\'historique: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSession(TakeChargeSession session) async {
    try {
      final box = await _box;
      await box.put(session.sessionId, session);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la mise à jour: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      final box = await _box;
      await box.delete(sessionId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la suppression: ${e.toString()}'));
    }
  }
}
