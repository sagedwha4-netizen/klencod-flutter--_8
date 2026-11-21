# مشروع ذكري | Dhikri

مشروع Flutter كامل المصدر لمسبحة إلكترونية عربية.

## المزايا
- عداد تسبيح دائري مع مؤشر تقدم.
- ستة أذكار جاهزة.
- أهداف 33 و99 و100.
- تراجع عن آخر ضغطة وتصفير عداد الذكر الحالي.
- إحصائية اليوم والإجمالي.
- إنجازات عند الوصول إلى 33 و99 و500 و1000.
- حفظ تلقائي محلي باستخدام SharedPreferences.
- اهتزاز اختياري ومظهر ليلي/نهاري.
- لا يحتاج إلى حساب أو Firebase أو اتصال بالإنترنت أثناء الاستخدام.

## البناء
1. افتح المجلد في بيئة تدعم Flutter.
2. استخدم Java 17.
3. نفّذ:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter build apk --release
   ```
4. ملف APK يظهر في:
   `build/app/outputs/flutter-apk/app-release.apk`

## إصلاح خطأ Android V1 Embedding
هذا المشروع يستخدم Android Embedding V2:
- `MainActivity.kt` ترث من `io.flutter.embedding.android.FlutterActivity`.
- يحتوي `AndroidManifest.xml` على `flutterEmbedding = 2`.
- لا يستخدم `io.flutter.app.*` أو `GeneratedPluginRegistrant`.

## ملاحظات مهمة
- `shared_preferences` مطلوب لحفظ البيانات بين مرات تشغيل التطبيق؛ أول بناء يحتاج تنزيل الحزمة مرة واحدة.
- لا يمكنني تأكيد خلو البناء من كل أخطاء بيئة جهازك دون تشغيل Flutter/Gradle على نفس بيئة البناء لديك. لكن ملفات Android هنا مُعدة لتجنب سبب الخطأ السابق الخاص بـ Android V1 Embedding.
