import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/phone_record.dart';
import '../services/firestore_sync_service.dart';
import '../services/phone_scanner_service.dart';
import '../widgets/consent_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scanner = PhoneScannerService();
  final _firestoreSync = FirestoreSyncService();

  bool _isWorking = false;
  String _statusText = 'جاهز لفحص أرقام الهاتف ومزامنتها بعد موافقتك.';
  ScanSummary? _lastSummary;
  String _searchQuery = '';

  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الدخول: $e')),
      );
    }
  }

  /// الخطوة الأساسية: إظهار التنبيه ← انتظار الضغط على "موافق" ← الفحص ← التخزين في Firestore
  Future<void> _handleScanAndSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول بحساب Google أولاً لحفظ الأرقام في السحابة.')),
      );
      return;
    }

    // 1. إظهار التنبيه البسيط للمستخدم أولاً
    final agreed = await showPhoneSyncConsentDialog(context);
    if (!agreed) {
      setState(() => _statusText = 'تم إلغاء العملية بناءً على اختيارك.');
      return;
    }

    setState(() {
      _isWorking = true;
      _statusText = 'جاري التحقق من إذن جهات الاتصال...';
    });

    try {
      // 2. طلب إذن الوصول إلى جهات الاتصال
      final granted = await _scanner.requestContactsPermission();
      if (!granted) {
        setState(() {
          _isWorking = false;
          _statusText = 'لم يتم منح إذن قراءة جهات الاتصال.';
        });
        return;
      }

      // 3. فحص الأرقام وتنقيتها وإزالة التكرار
      setState(() => _statusText = 'جاري فحص الأرقام وإزالة التكرار...');
      final summary = await _scanner.scanAndValidateContacts();

      // 4. تخزين الأرقام الصالحة في قاعدة بيانات Firestore السحابية
      setState(() => _statusText = 'جاري حفظ ${summary.validCount} رقماً في Firestore...');
      await _firestoreSync.syncValidatedNumbers(user: user, summary: summary);

      setState(() {
        _lastSummary = summary;
        _isWorking = false;
        _statusText = 'تمت المزامنة بنجاح: ${summary.validCount} رقم محفوظ في قاعدة البيانات.';
      });
    } catch (e) {
      setState(() {
        _isWorking = false;
        _statusText = 'حدث خطأ أثناء المزامنة: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: const Text(
              AppConfig.appName,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            actions: [
              if (user != null)
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل الدخول لحفظ الأرقام بأمان',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'يتم عزل الأرقام المفحوصة داخل مسارك الخاص في Cloud Firestore.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('تسجيل الدخول بحساب Google'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _statusText,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isWorking ? null : _handleScanAndSync,
                          icon: _isWorking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.contacts_outlined),
                          label: Text(_isWorking ? 'جاري الفحص والمزامنة...' : 'فحص وسحب الأرقام'),
                        ),
                      ],
                    ),
                  ),
                  if (_lastSummary != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MetricTile(label: 'المفحوصة', value: _lastSummary!.totalScanned),
                        const SizedBox(width: 8),
                        _MetricTile(label: 'الصالحة', value: _lastSummary!.validCount),
                        const SizedBox(width: 8),
                        _MetricTile(label: 'المكررة', value: _lastSummary!.duplicateCount),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو رقم الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<CloudPhoneRecord>>(
                      stream: _firestoreSync.watchSyncedRecords(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final all = snapshot.data ?? [];
                        final filtered = _searchQuery.isEmpty
                            ? all
                            : all
                                .where((r) =>
                                    r.displayName.contains(_searchQuery) ||
                                    r.normalizedNumber.contains(_searchQuery))
                                .toList();

                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد أرقام محفوظة حتى الآن.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListTile(
                              tileColor: Colors.white,
                              title: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                item.normalizedNumber,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF0284C7)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                                onPressed: () => _firestoreSync.deleteRecord(user.uid, item.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final int value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
