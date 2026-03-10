# Module Alert - Gestion des Alertes d'Urgence

## Vue d'ensemble
Ce module gère la réception et le traitement des alertes d'urgence émises par les bracelets connectés via Bluetooth Low Energy (BLE).

## Structure

### Domain Layer

#### Entities
- **EmergencyAlert** (typeId: 20): Représente une alerte d'urgence
  - alertId: Identifiant unique de l'alerte
  - victimDeviceId: ID du bracelet de la victime
  - vitalSigns: Signes vitaux au moment de l'alerte
  - estimatedLocation: Position estimée (optionnelle)
  - distance: Distance en mètres (calculée)
  - bearing: Direction en degrés (0-360)
  - status: Statut de l'alerte (active, acknowledged, beingHandled, resolved, ignored)
  - receivedAt: Date/heure de réception
  - handledByUserId: ID du bénévole qui prend en charge

- **AlertLocation** (typeId: 21): Position géographique
  - latitude, longitude, accuracy

- **AlertStatus** (typeId: 27): Enum pour le statut des alertes

#### Repository
- **AlertRepository**: Interface pour la gestion des alertes
  - getAlertStream(): Stream des alertes reçues
  - acknowledgeAlert(): Marquer comme acquittée
  - ignoreAlert(): Ignorer une alerte
  - getActiveAlerts(): Récupérer les alertes actives
  - getAlertHistory(): Historique des alertes
  - updateAlertStatus(): Mettre à jour le statut
  - updateAlertLocation(): Calculer distance/direction
  - saveAlert(), deleteAlert(): Persistance

## Flux de données

1. Le bracelet de la victime émet une alerte BLE
2. L'AlertListenerService (à implémenter) détecte l'alerte
3. L'alerte est parsée et transformée en EmergencyAlert
4. L'alerte est diffusée via le stream du repository
5. L'AlertBloc (à implémenter) gère les états et actions
6. L'UI affiche la notification et permet la navigation

## Prochaines étapes (Étape 2)
- Implémenter AlertListenerService pour écouter les alertes BLE
- Implémenter AlertRepositoryImpl avec Hive pour la persistance
- Créer AlertBloc pour la logique métier
- Intégrer avec BluetoothService existant
