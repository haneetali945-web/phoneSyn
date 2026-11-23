import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../models/phone_record.dart';

class PhoneScannerService {
  static const List<String> _knownCodes = [
    '+964', '+966', '+971', '+965', '+974', '+968', '+973', '+962', '+20', '+1', '+44',
  ];

  /// طلب إذن الوصول إلى جهات الاتصال بعد موافقة المستخدم
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// قراءة وفحص وتنقية أرقام الهاتف وإزالة التكرار
  Future<ScanSummary> scanAndValidateContacts() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final seenNumbers = <String>{};
    final validItems = <ScannedPhoneItem>[];

    int totalScanned = 0;
    int duplicateCount = 0;
    int invalidCount = 0;

    for (final contact in contacts) {
      final contactName = contact.displayName.trim().isEmpty
          ? 'جهة اتصال'
          : contact.displayName.trim();

      for (final phone in contact.phones) {
        totalScanned++;
        final raw = phone.number.trim();
        final normalized = _normalizePhone(raw, AppConfig.defaultCountryCode);

        if (normalized == null) {
          invalidCount++;
          continue;
        }

        if (AppConfig.filterByCountryCode &&
            !normalized.startsWith(AppConfig.defaultCountryCode)) {
          invalidCount++;
          continue;
        }

        if (seenNumbers.contains(normalized)) {
          duplicateCount++;
          continue;
        }

        seenNumbers.add(normalized);
        validItems.add(
          ScannedPhoneItem(
            displayName: contactName.length > 120 ? contactName.substring(0, 120) : contactName,
            rawNumber: raw.length > 40 ? raw.substring(0, 40) : raw,
            normalizedNumber: normalized,
            countryCode: _detectCountryCode(normalized, AppConfig.defaultCountryCode),
            carrierHint: _detectCarrierHint(normalized),
            status: PhoneValidationStatus.valid,
          ),
        );
      }
    }

    return ScanSummary(
      totalScanned: totalScanned,
      validCount: validItems.length,
      duplicateCount: duplicateCount,
      invalidCount: invalidCount,
      validItems: validItems,
    );
  }

  String _toAsciiDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      final idx1 = arabicIndic.indexOf(ch);
      if (idx1 != -1) {
        buffer.write(idx1);
        continue;
      }
      final idx2 = easternArabic.indexOf(ch);
      if (idx2 != -1) {
        buffer.write(idx2);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  String? _normalizePhone(String rawInput, String defaultCountry) {
    final ascii = _toAsciiDigits(rawInput).trim();
    if (ascii.isEmpty) return null;

    var cleaned = ascii.replaceAll(RegExp(r'[\s\-().]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7 || digits.length > 15) return null;
      return '+$digits';
    }

    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) return null;

    final safeCountry = defaultCountry.startsWith('+') ? defaultCountry : '+$defaultCountry';
    final localBody = digitsOnly.startsWith('0') ? digitsOnly.substring(1) : digitsOnly;
    final full = '$safeCountry$localBody';

    if (!RegExp(r'^\+[0-9]{7,18}$').hasMatch(full)) return null;
    return full;
  }

  String _detectCountryCode(String normalized, String fallback) {
    for (final code in _knownCodes) {
      if (normalized.startsWith(code)) return code;
    }
    final match = RegExp(r'^\+(\d{1,3})').firstMatch(normalized);
    return match != null ? '+${match.group(1)}' : fallback;
  }

  String _detectCarrierHint(String normalized) {
    if (normalized.startsWith('+96477')) return 'آسيا سيل';
    if (normalized.startsWith('+96478')) return 'زين العراق';
    if (normalized.startsWith('+96475')) return 'كورك';
    if (normalized.startsWith('+9665')) return 'جوال السعودية';
    if (normalized.startsWith('+9715')) return 'اتصالات الإمارات';
    return 'دولي';
  }
}
