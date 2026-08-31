// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      isExpense: fields[4] as bool,
      category: fields[5] as String,
      accountId: fields[6] as String,
      userId: fields[7] as String?,
      smsBody: fields[8] as String?,
      referenceNumber: fields[9] as String?,
      bankName: fields[10] as String?,
      accountLast4: fields[11] as String?,
      isExcluded: fields[12] as bool,
      notes: fields[13] as String?,
      receiptPath: fields[14] as String?,
      receiptBase64: fields[15] as String?,
      subcategory: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isExpense)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.accountId)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.smsBody)
      ..writeByte(9)
      ..write(obj.referenceNumber)
      ..writeByte(10)
      ..write(obj.bankName)
      ..writeByte(11)
      ..write(obj.accountLast4)
      ..writeByte(12)
      ..write(obj.isExcluded)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.receiptPath)
      ..writeByte(15)
      ..write(obj.receiptBase64)
      ..writeByte(16)
      ..write(obj.subcategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
