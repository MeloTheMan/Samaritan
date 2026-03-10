# Guide de Test - Module d'Intervention Samaritan

## Vue d'ensemble

Ce guide explique comment tester le module d'intervention complet avec le firmware `samaritan_bracelet_test.ino`.

## Matériel requis

- ESP32 DevKit (4MB Flash minimum)
- Câble USB
- Smartphone Android avec l'app Samaritan installée

## Installation du firmware

1. Ouvrir Arduino IDE
2. Charger `samaritan_bracelet_test.ino`
3. Sélectionner la carte : ESP32 Dev Module
4. Configurer :
   - Upload Speed: 115200
   - Flash Frequency: 80MHz
   - Flash Mode: QIO
   - Flash Size: 4MB
5. Téléverser le firmware
6. Ouvrir le moniteur série (115200 baud)

## Scénarios de test disponibles

### 1. STABLE (Baseline)
- **Température**: 36.5°C ±0.5
- **Rythme cardiaque**: 75 BPM ±5
- **SpO2**: 98% ±2
- **Pronostic attendu**: STABLE
- **Recommandations**: Surveillance continue

### 2. HYPOTHERMIA (Critique)
- **Température**: < 35°C
- **Rythme cardiaque**: ~50 BPM
- **SpO2**: ~92%
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences, réchauffement

### 3. HYPERTHERMIA (Critique)
- **Température**: > 40°C
- **Rythme cardiaque**: ~110 BPM
- **SpO2**: ~94%
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences, refroidissement

### 4. BRADYCARDIA (Critique)
- **Température**: ~36°C
- **Rythme cardiaque**: < 40 BPM
- **SpO2**: ~93%
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences, RCP si nécessaire

### 5. TACHYCARDIA (Critique)
- **Température**: ~37.5°C
- **Rythme cardiaque**: > 140 BPM
- **SpO2**: ~95%
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences, calmer la victime

### 6. HYPOXIA (Critique)
- **Température**: ~36°C
- **Rythme cardiaque**: ~95 BPM
- **SpO2**: < 90%
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences, PLS, libérer voies respiratoires

### 7. FALL_TRAUMA (Modéré/Grave)
- **Température**: ~36°C
- **Rythme cardiaque**: ~90 BPM
- **SpO2**: ~93%
- **Chute détectée**: OUI
- **Pronostic attendu**: MODERATE ou SERIOUS
- **Recommandations**: Vérifier blessures, ne pas déplacer

### 8. CARDIAC_ARREST (Critique)
- **Température**: ~35°C
- **Rythme cardiaque**: < 30 BPM
- **SpO2**: ~75%
- **Chute détectée**: OUI
- **Pronostic attendu**: CRITICAL
- **Recommandations**: Appel urgences immédiat, RCP

### 9. IMPROVING (Évolution positive)
- **Évolution**: Amélioration progressive sur 30 secondes
- **Départ**: État critique
- **Arrivée**: État stable
- **Pronostic**: CRITICAL → SERIOUS → MODERATE → STABLE

### 10. DETERIORATING (Évolution négative)
- **Évolution**: Dégradation progressive sur 30 secondes
- **Départ**: État stable
- **Arrivée**: État critique
- **Pronostic**: STABLE → MODERATE → SERIOUS → CRITICAL

## Commandes disponibles

### Via Serial Monitor

```
SCENARIO:X  - Activer le scénario X (1-10)
AUTO        - Mode automatique (cycle tous les scénarios)
ALERT       - Émettre une alerte d'urgence
HANDLED     - Marquer comme pris en charge
END         - Terminer l'intervention
RESET       - Retour à l'état stable
```

### Via App Samaritan (BLE)

Les mêmes commandes peuvent être envoyées via la caractéristique de commande BLE.

## Procédure de test complète

### Test 1: Flux complet d'intervention

1. **Préparation**
   ```
   RESET
   SCENARIO:8  (Arrêt cardiaque)
   ```

2. **Émission d'alerte**
   ```
   ALERT
   ```
   - ✓ Vérifier réception dans l'app (onglet Interventions)
   - ✓ Vérifier notification
   - ✓ Vérifier distance/direction

3. **Navigation**
   - ✓ Ouvrir AlertNotificationScreen
   - ✓ Vérifier affichage signes vitaux
   - ✓ Cliquer "Aller vers la victime"
   - ✓ Vérifier boussole et distance

4. **Prise en charge**
   - ✓ Cliquer "Prendre en charge"
   - ✓ Vérifier connexion au bracelet
   - ✓ Vérifier analyse du pronostic (CRITICAL attendu)
   - ✓ Vérifier recommandations appropriées

5. **Pendant l'intervention**
   ```
   SCENARIO:9  (Amélioration)
   ```
   - ✓ Vérifier mise à jour temps réel des signes vitaux
   - ✓ Vérifier évolution du pronostic
   - ✓ Ajouter des actions de soins
   - ✓ Tester "Affiner avec l'IA"

6. **Fin d'intervention**
   - ✓ Cliquer "Terminer l'intervention"
   - ✓ Sélectionner issue (ex: "Victime réanimée")
   - ✓ Ajouter notes
   - ✓ Valider
   - ✓ Vérifier sauvegarde session

### Test 2: Mode automatique

1. **Activer mode auto**
   ```
   AUTO
   ```

2. **Observer**
   - ✓ Changement de scénario toutes les 30s
   - ✓ Mise à jour automatique dans l'app
   - ✓ Adaptation des recommandations

### Test 3: Scénarios critiques

Pour chaque scénario critique (2-6, 8):

1. **Activer scénario**
   ```
   SCENARIO:X
   ALERT
   ```

2. **Vérifier**
   - ✓ Pronostic = CRITICAL
   - ✓ Facteurs critiques identifiés
   - ✓ Recommandations incluent "Appeler urgences"
   - ✓ Couleur rouge dans l'UI

### Test 4: Chute et traumatisme

1. **Activer scénario**
   ```
   SCENARIO:7
   ALERT
   ```

2. **Vérifier**
   - ✓ Indicateur "Chute détectée"
   - ✓ Recommandations spécifiques (ne pas déplacer)
   - ✓ Pronostic MODERATE ou SERIOUS

### Test 5: Évolutions progressives

1. **Test amélioration**
   ```
   SCENARIO:9
   ```
   - ✓ Observer amélioration progressive
   - ✓ Vérifier changement de pronostic

2. **Test dégradation**
   ```
   SCENARIO:10
   ```
   - ✓ Observer dégradation progressive
   - ✓ Vérifier changement de pronostic
   - ✓ Vérifier apparition chute après 10s

## Validation des seuils

### Seuils critiques (VitalSignsAnalyzer)

| Paramètre | Critique | Sérieux | Normal |
|-----------|----------|---------|--------|
| Température | < 35°C ou > 40°C | < 35.5°C ou > 39°C | 36-38°C |
| Rythme cardiaque | < 40 ou > 140 BPM | < 50 ou > 120 BPM | 60-100 BPM |
| SpO2 | < 90% | < 92% | > 95% |

### Vérification

Pour chaque scénario, comparer:
- Valeurs envoyées (Serial Monitor)
- Pronostic calculé (App)
- Recommandations générées (App)

## Checklist de validation

### Module Alert
- [ ] Réception d'alerte BLE
- [ ] Parsing correct des données
- [ ] Calcul distance/direction
- [ ] Notification système
- [ ] Affichage AlertNotificationScreen
- [ ] Navigation vers victime
- [ ] Boussole fonctionnelle

### Module Intervention
- [ ] Prise en charge
- [ ] Connexion bracelet victime
- [ ] Analyse pronostic automatique
- [ ] Affichage signes vitaux temps réel
- [ ] Génération recommandations
- [ ] Ajout actions de soins
- [ ] Fin d'intervention
- [ ] Sélection issue
- [ ] Sauvegarde session

### VitalSignsAnalyzer
- [ ] Détection hypothermie
- [ ] Détection hyperthermie
- [ ] Détection bradycardie
- [ ] Détection tachycardie
- [ ] Détection hypoxie
- [ ] Détection chute
- [ ] Génération recommandations appropriées
- [ ] Calcul niveau pronostic correct

### Persistance
- [ ] Sauvegarde alertes (Hive)
- [ ] Sauvegarde sessions (Hive)
- [ ] Historique alertes
- [ ] Historique interventions
- [ ] Récupération après redémarrage

## Problèmes connus et solutions

### Bracelet non détecté
- Vérifier Bluetooth activé
- Vérifier permissions app
- Redémarrer ESP32
- Vérifier Serial Monitor pour erreurs

### Pas de notification d'alerte
- Vérifier permissions notifications
- Vérifier app en premier plan
- Tester commande ALERT manuellement

### Signes vitaux non mis à jour
- Vérifier connexion BLE active
- Vérifier Serial Monitor (envoi toutes les 1s)
- Redémarrer connexion

### Pronostic incorrect
- Vérifier valeurs dans Serial Monitor
- Comparer avec seuils VitalSignsAnalyzer
- Vérifier logs app

## Logs et débogage

### Serial Monitor (ESP32)
```
📊 [SCENARIO] Temp: XX.X°C | HR: XXX BPM | SpO2: XXX% | Fall: ✓/✗ | Move: ✓/✗
```

### App Logs
- Utiliser `flutter run` pour voir logs en temps réel
- Vérifier états BLoC
- Vérifier parsing BLE

## Résultats attendus

Après tests complets:
- ✅ 10 scénarios testés
- ✅ Tous les pronostics corrects
- ✅ Toutes les recommandations appropriées
- ✅ Flux complet fonctionnel
- ✅ Persistance validée
- ✅ UI responsive et claire

## Support

En cas de problème:
1. Vérifier ce guide
2. Consulter Serial Monitor
3. Vérifier logs Flutter
4. Tester avec firmware de base (samaritan_bracelet.ino)

---

**Bon test ! 🚑**
