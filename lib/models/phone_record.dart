import 'package:cloud_firestore/cloud_firestore.dart';

enum PhoneValidationStatus { valid, duplicate, invalid }

class ScannedPhoneItem {
  final String displayName;
  final String rawNumber;
  final String normalizedNumber;
  final String countryCode;
  final String carrierHint;
  final PhoneValidationStatus status;
  final String? reason;

  const ScannedPhoneItem({
    required this.displayName,
    required this.rawNumber,
    required this.normalizedNumber,
    required this.countryCode,
    required this.carrierHint,
    required this.status,
    this.reason,
  });

  String get docId {
    final digits = normalizedNumber.replaceAll(RegExp(r'\D'), '');
    return 'rec_$digits';
  }
}

class ScanSummary {
  final int totalScanned;
  final int validCount;
  final int duplicateCount;
  final int invalidCount;
  final List<ScannedPhoneItem> validItems;

  const ScanSummary({
    required this.totalScanned,
    required this.validCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.validItems,
  });
}

class CloudPhoneRecord {
  final String id;
  final String ownerUid;
  final String displayName;
  final String rawNumber;
  final String normalizedNumber;
  final String countryCode;
  final String carrierHint;
  final String batchId;
  final DateTime? updatedAt;

  const CloudPhoneRecord({
    required this.id,
    required this.ownerUid,
    required this.displayName,
    required this.rawNumber,
    required this.normalizedNumber,
    required this.countryCode,
    required this.carrierHint,
    required this.batchId,
    this.updatedAt,
  });

  factory CloudPhoneRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['updatedAt'];
    return CloudPhoneRecord(
      id: doc.id,
      ownerUid: (data['ownerUid'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      rawNumber: (data['rawNumber'] ?? '') as String,
      normalizedNumber: (data['normalizedNumber'] ?? '') as String,
      countryCode: (data['countryCode'] ?? '') as String,
      carrierHint: (data['carrierHint'] ?? '') as String,
      batchId: (data['batchId'] ?? '') as String,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
