import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/app_config.dart';
import '../models/phone_record.dart';

class FirestoreSyncService {
  FirebaseFirestore get _db => AppConfig.firestoreDatabaseId == '(default)'
      ? FirebaseFirestore.instance
      : FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: AppConfig.firestoreDatabaseId,
        );

  /// التأكد من وجود سجل المستخدم الأساسي قبل الحفظ
  Future<void> ensureUserProfile(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final snap = await userRef.get();
    final name = (user.displayName ?? user.email?.split('@').first ?? 'مستخدم').trim();
    final email = (user.email ?? 'user@example.com').trim();

    if (!snap.exists) {
      await userRef.set({
        'uid': user.uid,
        'displayName': name.length > 120 ? name.substring(0, 120) : name,
        'email': email.length > 160 ? email.substring(0, 160) : email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        'displayName': name.length > 120 ? name.substring(0, 120) : name,
        'email': email.length > 160 ? email.substring(0, 160) : email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// حفظ دفعة الأرقام المفحوصة بعد موافقة المستخدم الصريحة
  Future<String> syncValidatedNumbers({
    required User user,
    required ScanSummary summary,
  }) async {
    await ensureUserProfile(user);

    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    final batchRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('sync_batches')
        .doc(batchId);

    await batchRef.set({
      'ownerUid': user.uid,
      'totalScanned': summary.totalScanned,
      'validCount': summary.validCount,
      'duplicateCount': summary.duplicateCount,
      'invalidCount': summary.invalidCount,
      'consentAccepted': true,
      'consentText': AppConfig.consentMessage,
      'deviceLabel': 'Flutter Mobile App',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final records = summary.validItems;
    for (int i = 0; i < records.length; i += 400) {
      final chunk = records.sublist(i, (i + 400).clamp(0, records.length));
      final writeBatch = _db.batch();

      for (final item in chunk) {
        final docRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('phone_records')
            .doc(item.docId);

        final existing = await docRef.get();
        if (existing.exists) {
          writeBatch.update(docRef, {
            'displayName': item.displayName,
            'rawNumber': item.rawNumber,
            'countryCode': item.countryCode,
            'carrierHint': item.carrierHint,
            'sourceLabel': 'flutter_device',
            'batchId': batchId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          writeBatch.set(docRef, {
            'ownerUid': user.uid,
            'displayName': item.displayName,
            'rawNumber': item.rawNumber,
            'normalizedNumber': item.normalizedNumber,
            'countryCode': item.countryCode,
            'carrierHint': item.carrierHint,
            'sourceLabel': 'flutter_device',
            'batchId': batchId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await writeBatch.commit();
    }

    return batchId;
  }

  /// متابعة الأرقام المحفوظة في السحابة بشكل فوري
  Stream<List<CloudPhoneRecord>> watchSyncedRecords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('phone_records')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CloudPhoneRecord.fromFirestore).toList());
  }

  Future<void> deleteRecord(String uid, String recordId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('phone_records')
        .doc(recordId)
        .delete();
  }
}
