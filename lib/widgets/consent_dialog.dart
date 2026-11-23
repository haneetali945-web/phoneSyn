import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// نافذة تنبيه بسيطة وواضحة تطلب موافقة المستخدم قبل فحص وسحب الأرقام
Future<bool> showPhoneSyncConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppConfig.consentTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: const Text(
            AppConfig.consentMessage,
            style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppConfig.cancelButtonLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(AppConfig.agreeButtonLabel),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
