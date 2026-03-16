import 'package:hive/hive.dart';

class HiveMigration {
  static Future<void> migrateVitalSignsData() async {
    try {
      // Essayer d'ouvrir la box des signes vitaux
      final box = await Hive.openBox('vital_signs');
      
      // Si la box contient des données anciennes incompatibles, la vider
      if (box.isNotEmpty) {
        print('Migration: Nettoyage des anciennes données VitalSigns...');
        await box.clear();
        print('Migration: Données VitalSigns nettoyées avec succès');
      }
      
      await box.close();
    } catch (e) {
      print('Migration: Erreur lors de la migration des VitalSigns: $e');
      
      // Si l'ouverture échoue à cause d'un conflit de structure,
      // supprimer complètement la box
      try {
        await Hive.deleteBoxFromDisk('vital_signs');
        print('Migration: Box VitalSigns supprimée et recréée');
      } catch (deleteError) {
        print('Migration: Erreur lors de la suppression: $deleteError');
      }
    }
  }
  
  static Future<void> migrateAllBoxes() async {
    final boxesToMigrate = [
      'vital_signs',
      'device_settings',
      'wearable_devices',
      'emergency_alerts',
      'take_charge_sessions',
    ];
    
    for (final boxName in boxesToMigrate) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        print('Migration: Box $boxName nettoyée');
      } catch (e) {
        print('Migration: Erreur lors du nettoyage de $boxName: $e');
      }
    }
    
    print('Migration: Toutes les boxes ont été nettoyées');
  }
}