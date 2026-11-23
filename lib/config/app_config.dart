/// إعدادات التطبيق المركزية - يمكنك تعديل أي قيمة هنا بسهولة
class AppConfig {
  static const String appName = 'فاحص ومزامن الأرقام';
  static const String defaultCountryCode = '+964';
  static const bool filterByCountryCode = false;

  // نصوص نافذة التنبيه والموافقة قبل سحب الأرقام
  static const String consentTitle = 'تنبيه مزامنة أرقام الهاتف';
  static const String consentMessage = 'سيقوم التطبيق بفحص أرقام الهاتف في جهازك، التحقق من صحتها وإزالة المكرر، ثم حفظ الأرقام الصالحة في قاعدة البيانات السحابية. هل توافق على المتابعة؟';
  static const String agreeButtonLabel = 'موافق';
  static const String cancelButtonLabel = 'إلغاء';

  // معرف قاعدة بيانات Firestore (اترك '(default)' عند استخدام قاعدة بياناتك الافتراضية)
  static const String firestoreDatabaseId = 'ai-studio-4335a14d-5e9b-4b11-a1df-ff618393f22c';
}
