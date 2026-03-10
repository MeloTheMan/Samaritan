import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/take_charge_session.dart';
import '../entities/care_action.dart';
import '../entities/intervention_outcome.dart';
import '../../../device/domain/entities/vital_signs.dart';

abstract class InterventionRepository {
  /// Créer une nouvelle session de prise en charge
  Future<Either<Failure, TakeChargeSession>> createSession({
    required String victimDeviceId,
    required String volunteerId,
    required String alertId,
  });

  /// Récupérer la session active
  Future<Either<Failure, TakeChargeSession?>> getActiveSession();

  /// Ajouter une action de soins à la session
  Future<Either<Failure, void>> addCareAction(
    String sessionId,
    CareAction action,
  );

  /// Ajouter des signes vitaux à l'historique de la session
  Future<Either<Failure, void>> addVitalSigns(
    String sessionId,
    VitalSigns vitalSigns,
  );

  /// Terminer une session avec l'issue
  Future<Either<Failure, void>> endSession(
    String sessionId,
    InterventionOutcome outcome,
  );

  /// Récupérer une session par ID
  Future<Either<Failure, TakeChargeSession>> getSession(String sessionId);

  /// Récupérer l'historique des sessions
  Future<Either<Failure, List<TakeChargeSession>>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Mettre à jour une session
  Future<Either<Failure, void>> updateSession(TakeChargeSession session);

  /// Supprimer une session
  Future<Either<Failure, void>> deleteSession(String sessionId);
}
