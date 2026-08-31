# دفتر الحسناوي (mysheetapp)

تطبيق Android مبني بـ Flutter لتسجيل العمليات المالية مباشرة داخل Google Sheets، مع رفع صور الوصولات إلى Google Drive وحفظ روابطها في نفس الصف. يعمل بدون إنترنت (Offline-first) ويزامن العمليات المعلّقة تلقائياً عند عودة الاتصال.

## المزايا المطبّقة

- ترقيم رديف تلقائي وتسلسلي (بدون تكرار)، مع إمكانية التعديل اليدوي من الإعدادات.
- حقل بيان متعدد الأسطر، صورة وصل (كاميرا/معرض) أو ملاحظة نصية بديلة، أو الاثنان معاً.
- حقلا "مدين له" و"مدين عليه" مع تحقق كامل من صحة الإدخال.
- ربط قابل للتخصيص بالكامل من الإعدادات: Spreadsheet ID، اسم Sheet، Drive Folder ID، عناوين الأعمدة، رقم بداية الرديف، العملة، المظهر.
- تسجيل دخول Google رسمي (OAuth 2.0) بأقل الصلاحيات الممكنة (`spreadsheets` و`drive.file` فقط).
- تخزين محلي (SQLite) لكل عملية قبل رفعها؛ حالة "بانتظار المزامنة" ↔ "تمت المزامنة"، مع زر "مزامنة الآن" ومزامنة تلقائية عند عودة الإنترنت.
- منع التكرار عبر معرّف عملية فريد (Transaction ID / UUID) يُكتب في العمود I ويُتحقق منه قبل أي إعادة محاولة.
- صفحتا "سجل العمليات" و"تفاصيل العملية"، وصفحة إعدادات كاملة.
- لا يوجد أي مفتاح أو سرّ مضمّن داخل الكود أو الـ APK.

## هيكل المشروع

```
lib/
  core/            ثوابت، أخطاء، تنسيقات، الثيم، إعداد وقت البناء (Env)
  domain/models/   نماذج البيانات (LedgerEntry, AppSettings, SyncStatus)
  data/
    local/         قاعدة بيانات SQLite (sqflite) وDAO
    services/      GoogleAuthService, GoogleSheetsService, GoogleDriveService,
                    SettingsService, ConnectivityService
    repositories/  LedgerRepository (تنسيق العمل بين المحلي والسحابي والمزامنة)
  presentation/
    providers/     إدارة الحالة (Riverpod)
    screens/       الرئيسية، السجل، التفاصيل، الإعدادات، تسجيل الدخول
    widgets/       عناصر واجهة قابلة لإعادة الاستخدام
```

---

## 1) إعداد Google Cloud Console (خطوة بخطوة)

### 1.1 إنشاء مشروع

1. افتح <https://console.cloud.google.com/>.
2. من القائمة العلوية اختر **New Project**، أعطه اسماً (مثال: `hasnawi-ledger`) ثم **Create**.
3. تأكد أن المشروع الجديد محدد أعلى الصفحة.

### 1.2 تفعيل Google Sheets API وGoogle Drive API

1. من القائمة الجانبية: **APIs & Services → Library**.
2. ابحث عن **Google Sheets API** واضغط **Enable**.
3. ابحث عن **Google Drive API** واضغط **Enable**.

### 1.3 إعداد OAuth Consent Screen

1. **APIs & Services → OAuth consent screen**.
2. اختر **External** (ما لم يكن لديك Google Workspace) ثم **Create**.
3. أدخل اسم التطبيق (نفس اسم التطبيق في الإعدادات)، بريدك الإلكتروني كـ Support email، وبريدك كـ Developer contact.
4. في خطوة **Scopes** أضف يدوياً (Add or remove scopes):
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/drive.file`
5. في خطوة **Test users** أضف بريدك (وأي مستخدمين آخرين) طالما التطبيق في وضع Testing.
6. احفظ. (لا حاجة للنشر Publish إلا إذا أردت فتح التطبيق لأي مستخدم Google).

### 1.4 إنشاء Android OAuth Client (بدون Secret)

هذا العميل مرتبط بـ **اسم الحزمة (Package Name) + بصمة التوقيع (SHA-1)** فقط، ولا يحتوي على Client Secret إطلاقاً - وهذا ما يجعله آمناً للتضمين داخل APK.

1. **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
2. Application type: **Android**.
3. Package name: `com.hasnawi.mysheetapp` (كما في `android/app/build.gradle.kts` → `applicationId`).
4. SHA-1 certificate fingerprint: احصل عليه من القسم 1.6 أدناه، ثم الصق القيمة هنا.
5. اضغط **Create**. (لا تحتاج لحفظ أي شيء من هذه الشاشة داخل التطبيق).

> كرر هذه الخطوة لاحقاً بمفتاح توقيع الإصدار النهائي (Release keystore) قبل نشر APK موقّع للمستخدمين، وأضف بصمته أيضاً كعميل Android منفصل (أو أضف SHA-1 و SHA-256 لنفس العميل إن كانت الواجهة تسمح بذلك).

### 1.5 إنشاء Web OAuth Client (مطلوب كـ serverClientId)

مكتبة `google_sign_in` على أندرويد تحتاج **Web Client ID** (وليس سرّه) لتمريره كـ `serverClientId` عند التهيئة - هذا معرّف عام وليس سرّاً.

1. **Credentials → Create Credentials → OAuth client ID**.
2. Application type: **Web application**.
3. أعطه اسماً (مثال: `mysheetapp-web`) واضغط **Create**.
4. انسخ **Client ID** الناتج (ينتهي بـ `.apps.googleusercontent.com`) - هذا ما تحتاجه في القسم 3.

### 1.6 الحصول على SHA-1 و SHA-256

من داخل مجلد المشروع:

```bash
cd android
./gradlew signingReport
```

أو مباشرة من مفتاح Debug الافتراضي (Windows):

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

انسخ قيمتي **SHA1** و**SHA256** الظاهرتين تحت `Variant: debug` والصقهما في نفس عميل Android الذي أنشأته في القسم 1.4 (Google Cloud Console يقبل أكثر من بصمة لنفس العميل).

عند إنشاء مفتاح توقيع للإصدار النهائي (القسم 4) كرر نفس الأمر على ملف الـ keystore الجديد وأضف بصمته أيضاً.

---

## 2) إعداد Google Sheet وGoogle Drive Folder

1. أنشئ Google Sheet جديد (أو استخدم موجوداً). شارك بريد حساب Google الذي ستسجّل دخولك به على الأقل بصلاحية **Editor** إن لم يكن مالك الشيت.
2. من رابط الشيت انسخ الـ **Spreadsheet ID** (الجزء بين `/d/` و`/edit`):
   `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit`
3. أنشئ مجلد Google Drive (أو استخدم موجوداً، أو أنشئه من داخل التطبيق نفسه من صفحة الإعدادات).
4. من رابط المجلد انسخ **Folder ID**:
   `https://drive.google.com/drive/folders/FOLDER_ID`
5. ألصق القيمتين في صفحة **الإعدادات** داخل التطبيق، ثم اضغط **اختبار الاتصال** في كل قسم.

ترتيب الأعمدة داخل الشيت ثابت (A..I) ويُنشأ صف العناوين تلقائياً عند أول عملية إن كان الصف الأول فارغاً:

| العمود | المحتوى |
|---|---|
| A | الرديف |
| B | التاريخ |
| C | الوقت |
| D | البيان |
| E | رابط صورة الوصل |
| F | النص أو الملاحظة |
| G | مدين له |
| H | مدين عليه |
| I | معرف العملية (Transaction ID) |

---

## 3) تشغيل التطبيق محلياً

يتطلب [Flutter SDK](https://docs.flutter.dev/get-started/install) و[Android Studio](https://developer.android.com/studio) (لتثبيت Android SDK) مثبّتين، وجهاز/محاكي أندرويد متصل.

```bash
flutter pub get
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxxxxxxx.apps.googleusercontent.com
```

استبدل القيمة بـ **Web Client ID** الذي نسخته في القسم 1.5. لا تضع هذه القيمة مباشرة داخل الكود ولا ترفعها لنظام تحكم الإصدار كسلسلة نصية ثابتة؛ استخدم `--dart-define` كما هو موضح، أو ملف محلي غير مُتتبَّع (`.gitignore` يستثني `env.local.json` و`*.env` مسبقاً) تقرأ منه هذه القيمة عبر سكربت البناء الخاص بك.

---

## 4) بناء APK

### إصدار Debug (للتجربة السريعة، موقّع بمفتاح Debug):

```bash
flutter build apk --debug --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxxxxxxx.apps.googleusercontent.com
```

الناتج: `build/app/outputs/flutter-apk/app-debug.apk`

### إصدار Release (للتوزيع - يتطلب مفتاح توقيع خاص بك):

1. أنشئ Keystore (مرة واحدة فقط، واحفظه في مكان آمن خارج المستودع):

   ```bash
   keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mysheetapp
   ```

2. أنشئ ملف `android/key.properties` (مُستثنى من Git تلقائياً) بالشكل التالي:

   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=mysheetapp
   storeFile=C:/path/to/release.jks
   ```

3. أضف بصمة SHA-1/SHA-256 لهذا المفتاح الجديد إلى عميل Android في Google Cloud Console (القسم 1.4/1.6).

4. ابنِ الإصدار:

   ```bash
   flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxxxxxxx.apps.googleusercontent.com
   ```

   الناتج: `build/app/outputs/flutter-apk/app-release.apk` - جاهز للتثبيت المباشر (Sideload) أو الرفع لمتجر.

> بدون `android/key.properties`، يستخدم إصدار Release مفتاح Debug تلقائياً حتى يبقى الأمر `flutter build apk --release` يعمل من أول تجربة - لكن هذا غير مناسب للتوزيع الفعلي للمستخدمين.

---

## 5) بناء iOS / IPA عبر Codemagic

بناء IPA يتطلب macOS وXcode إلزامياً من Apple - لا توجد طريقة لبنائه على Windows محلياً. هذا المشروع يحتوي على `codemagic.yaml` جاهز (workflow باسم `ios-ipa`) يبني IPA على أجهزة Mac سحابية عبر [Codemagic](https://codemagic.io) بدون الحاجة لامتلاك جهاز Mac.

### 5.1 إنشاء عميل iOS OAuth

1. في نفس مشروع Google Cloud (القسم 1): **Credentials → Create Credentials → OAuth client ID**.
2. Application type: **iOS**.
3. Bundle ID: `com.hasnawi.mysheetapp` (كما في `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`).
4. اضغط **Create** وانسخ الـ **Client ID** الناتج (ينتهي بـ `.apps.googleusercontent.com`).
5. احسب **Reversed Client ID**: اعكس ترتيب الجزأين قبل وبعد أول نقطة في الجزء الرقمي، مثال:
   - Client ID: `123456789-abcxyz.apps.googleusercontent.com`
   - Reversed: `com.googleusercontent.apps.123456789-abcxyz`

### 5.2 إعداد متغيرات البيئة في Codemagic

من إعدادات التطبيق في Codemagic → **Environment variables**، أضف (مع تفعيل **Secure**):

| المتغير | القيمة |
|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | نفس Web Client ID المستخدم في بناء أندرويد (القسم 1.5) |
| `GOOGLE_IOS_CLIENT_ID` | iOS Client ID من الخطوة 5.1 |
| `GOOGLE_IOS_REVERSED_CLIENT_ID` | القيمة المعكوسة من الخطوة 5.1 |

### 5.3 إعداد التوقيع (Code Signing)

بما أن لديك حساب Apple Developer وخبرة سابقة مع Codemagic:

1. من **Team settings → Integrations → App Store Connect**، أضف مفتاح API الخاص بحسابك وسمّه `app_store_connect` (أو غيّر الاسم في `codemagic.yaml` ليطابق ما اخترته).
2. تأكد من وجود App ID بنفس الـ Bundle ID (`com.hasnawi.mysheetapp`) في Apple Developer Portal (يمكن لـ Codemagic إنشاءه تلقائياً عند أول بناء إذا منحته الصلاحية).
3. لتوزيع Ad Hoc (تثبيت مباشر على أجهزتك دون App Store)، تأكد أن أجهزتك (UDIDs) مسجّلة في Apple Developer Portal حتى يشملها ملف التوقيع الذي ينشئه Codemagic تلقائياً.

### 5.4 تشغيل البناء

1. ارفع هذا المشروع (بما فيه `codemagic.yaml`) إلى مستودع Git (GitHub/GitLab/Bitbucket) واربطه بتطبيق جديد في Codemagic.
2. من صفحة التطبيق في Codemagic، شغّل الـ workflow **`ios-ipa`**.
3. بعد نجاح البناء، حمّل ملف الـ **IPA** من قسم **Artifacts**.
4. لتثبيته: عبر Apple Configurator، أو TestFlight (لو غيّرت `distribution_type` إلى `app_store` ورفعته)، أو أي أداة توزيع Ad Hoc تدعمها.

> لتشغيل التطبيق محلياً على جهاز Mac بدلاً من Codemagic: `flutter build ipa --release --dart-define=GOOGLE_SERVER_CLIENT_ID=... --dart-define=GOOGLE_IOS_CLIENT_ID=...`، بعد استبدال `__GOOGLE_IOS_REVERSED_CLIENT_ID__` يدوياً في `ios/Runner/Info.plist` بالقيمة المعكوسة من الخطوة 5.1.

---

## 6) ملاحظات أمنية

- لا يحتوي الكود ولا الـ APK/IPA على أي API Key أو Client Secret. `GOOGLE_SERVER_CLIENT_ID` و`GOOGLE_IOS_CLIENT_ID` معرّفات عامة (ليست أسراراً) وتُمرَّر وقت البناء فقط عبر `--dart-define` أو متغيرات بيئة Codemagic المشفّرة.
- عميلا Android وiOS في Google Cloud Console لا يملكان Secret أصلاً - الحماية تتم عبر مطابقة اسم الحزمة/Bundle ID وبصمة التوقيع من طرف Google/Apple.
- جلسة تسجيل الدخول تُدار بالكامل عبر SDK الرسمي لـ Google Sign-In؛ لا يقوم التطبيق بتخزين Access/Refresh Token بنفسه.
- نطاق الصلاحيات المطلوب هو الأدنى الممكن: `drive.file` (وليس `drive` الكامل) يعطي التطبيق وصولاً فقط للملفات التي ينشئها هو نفسه.

## 7) استكشاف الأخطاء الشائعة

| الرسالة | السبب المحتمل |
|---|---|
| فشل تسجيل الدخول / clientConfigurationError | SHA-1 غير مطابق، أو Package name غير مطابق، أو Web Client ID غير صحيح |
| تعذّر الوصول إلى Google Sheets | الحساب لا يملك صلاحية على الشيت، أو Spreadsheet ID خاطئ |
| تعذّر الوصول إلى Google Drive | Folder ID خاطئ، أو الحساب لا يملك صلاحية على المجلد |
| العملية تبقى "بانتظار المزامنة" | لا يوجد اتصال إنترنت - اضغط "مزامنة الآن" من صفحة السجل بعد عودة الاتصال |

---

**الحزمة/Bundle ID:** `com.hasnawi.mysheetapp` · **الحد الأدنى لإصدار أندرويد:** 7.0 (API 24) · **iOS:** يُبنى عبر Codemagic فقط (راجع القسم 5)
