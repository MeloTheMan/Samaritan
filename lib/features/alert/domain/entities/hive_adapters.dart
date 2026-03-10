import 'package:hive/hive.dart';
import 'emergency_alert.dart';

// Adapter pour AlertStatus enum
class AlertStatusAdapter extends TypeAdapter<AlertStatus> {
  @override
  final int typeId = 27;

  @override
  AlertStatus read(BinaryReader reader) {
    return AlertStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AlertStatus obj) {
    writer.writeByte(obj.index);
  }
}
