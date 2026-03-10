import 'package:hive/hive.dart';
import 'prognosis.dart';
import 'intervention_outcome.dart';

// Adapter pour PrognosisLevel enum
class PrognosisLevelAdapter extends TypeAdapter<PrognosisLevel> {
  @override
  final int typeId = 28;

  @override
  PrognosisLevel read(BinaryReader reader) {
    return PrognosisLevel.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PrognosisLevel obj) {
    writer.writeByte(obj.index);
  }
}

// Adapter pour OutcomeType enum
class OutcomeTypeAdapter extends TypeAdapter<OutcomeType> {
  @override
  final int typeId = 29;

  @override
  OutcomeType read(BinaryReader reader) {
    return OutcomeType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, OutcomeType obj) {
    writer.writeByte(obj.index);
  }
}
