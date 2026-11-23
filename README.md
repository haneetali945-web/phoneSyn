# فاحص ومزامن الأرقام (Flutter + Firebase Firestore)

مشروع **Flutter / Dart** متكامل يقوم بالخطوات التالية:
1. إظهار نافذة تنبيه بسيطة وواضحة للمستخدم قبل الوصول لأي أرقام.
2. عند ضغط المستخدم على **موافق**، يطلب التطبيق إذن جهات الاتصال.
3. يفحص الأرقام، يحوّل الأرقام العربية، يزيل التكرار والأرقام التالفة، ويطبّق رمز الدولة (+964).
4. يخزن الأرقام الصالحة في قاعدة بيانات **Firebase Firestore** السحابية مع عزل البيانات لكل مستخدم.

## خطوات التشغيل السريعة
```bash
# 1. تحميل المكتبات
flutter pub get

# 2. (اختياري لربط مشروع Firebase الخاص بك)
dart pub global activate flutterfire_cli
flutterfire configure

# 3. تشغيل التطبيق
flutter run
```

## أماكن التعديل السريع
- `lib/config/app_config.dart`: تعديل اسم التطبيق، نص التنبيه، ورمز الدولة الافتراضي.
- `lib/services/phone_scanner_service.dart`: تعديل قواعد التحقق من أرقام الهاتف أو تصفية الشبكات.
- `lib/widgets/consent_dialog.dart`: تعديل تصميم نافذة الموافقة.
- `lib/services/firestore_sync_service.dart`: تعديل مسار الحفظ أو الحقول المرسلة إلى Firestore.
