# Module Take Charge - Gestion des Interventions

## Vue d'ensemble
Ce module gère la prise en charge des victimes, l'analyse du pronostic vital, l'administration des soins et la documentation des interventions.

## Structure

### Domain Layer

#### Entities

- **TakeChargeSession** (typeId: 26): Session complète d'intervention
  - sessionId: Identifiant unique
  - victimDeviceId: ID du bracelet de la victime
  - volunteerId: ID du bénévole
  - startTime, endTime: Durée de l'intervention
  - initialPrognosis: Pronostic initial
  - vitalSignsHistory: Historique des signes vitaux
  - actionsPerformed: Actions de soins effectuées
  - outcome: Issue de l'intervention
  - alertId: Lien avec l'alerte d'origine

- **Prognosis** (typeId: 22): Analyse du pronostic vital
  - level: Niveau (critical, serious, moderate, stable)
  - description: Description textuelle
  - criticalFactors: Facteurs critiques identifiés
  - initialRecommendations: Recommandations de soins
  - analyzedAt: Date/heure de l'analyse

- **CriticalFactor** (typeId: 23): Facteur critique identifié
  - factor: Nom du facteur (température, rythme cardiaque, etc.)
  - severity: Sévérité (high, medium, low)
  - description: Description détaillée

- **CareAction** (typeId: 24): Action de soins effectuée
  - actionId, description
  - performedAt: Date/heure
  - duration: Durée de l'action
  - notes: Notes additionnelles
  - completed: Statut de complétion

- **InterventionOutcome** (typeId: 25): Issue de l'intervention
  - type: Type d'issue (resuscitated, hospitalTransport, improved, stable, deteriorating)
  - notes: Notes
  - recordedAt: Date/heure
  - additionalDetails: Détails supplémentaires

#### Services

- **VitalSignsAnalyzer**: Analyse les signes vitaux et génère un pronostic
  - analyzeVitalSigns(): Analyse complète avec seuils critiques
  - Génère automatiquement les recommandations de soins selon le niveau de gravité
  - Seuils configurés pour température, rythme cardiaque, saturation O2
  - Détection de chute intégrée

#### Repository

- **InterventionRepository**: Interface pour la gestion des sessions
  - createSession(): Créer une nouvelle session
  - getActiveSession(): Récupérer la session active
  - addCareAction(): Ajouter une action de soins
  - addVitalSigns(): Ajouter des signes vitaux
  - endSession(): Terminer avec l'issue
  - getSession(), getSessionHistory(): Récupération
  - updateSession(), deleteSession(): Gestion

## Logique d'analyse du pronostic

### Seuils critiques
- **Température**: < 35°C ou > 40°C → Critical
- **Rythme cardiaque**: < 40 BPM ou > 140 BPM → Critical
- **Saturation O2**: < 90% → Critical
- **Chute détectée**: → Moderate minimum

### Recommandations automatiques
- **Critical**: Appel urgences immédiat, RCP si nécessaire, PLS
- **Serious**: Appel urgences, surveillance constante
- **Moderate**: Surveillance, vérification blessures
- **Stable**: Surveillance continue, rassurer

## Prochaines étapes (Étape 2)
- Implémenter InterventionRepositoryImpl avec Hive
- Créer InterventionBloc pour la logique métier
- Intégrer VitalSignsAnalyzer dans le flux de prise en charge
- Gérer la connexion au bracelet de la victime
- Implémenter la diffusion des messages via le bracelet
