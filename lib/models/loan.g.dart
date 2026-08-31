// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 4;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      title: fields[1] as String,
      totalAmount: fields[2] as double,
      paidAmount: fields[3] as double,
      type: fields[4] as LoanType,
      startDate: fields[5] as DateTime,
      dueDate: fields[6] as DateTime?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.paidAmount)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoanTypeAdapter extends TypeAdapter<LoanType> {
  @override
  final int typeId = 3;

  @override
  LoanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanType.given;
      case 1:
        return LoanType.taken;
      default:
        return LoanType.given;
    }
  }

  @override
  void write(BinaryWriter writer, LoanType obj) {
    switch (obj) {
      case LoanType.given:
        writer.writeByte(0);
        break;
      case LoanType.taken:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
