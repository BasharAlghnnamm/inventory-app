// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام المخزون';

  @override
  String get homeTitle => 'جلسات المخزون';

  @override
  String get newSession => 'جلسة جديدة';

  @override
  String get sessionName => 'اسم الجلسة';

  @override
  String get create => 'إنشاء';

  @override
  String get createSession => 'إنشاء جلسة';

  @override
  String get continueScanning => 'يرجى مسح الباركود للبدء، أو تسجيل منتج جديد.';

  @override
  String get sessionCreated => 'تم إنشاء الجلسة';

  @override
  String get noSessions => 'لا توجد جلسات بعد. أنشئ جلستك الأولى.';

  @override
  String get searchSessions => 'Search sessions';

  @override
  String get noResults => 'No matching sessions';

  @override
  String get delete => 'حذف';

  @override
  String get deleteSessionTitle => 'حذف هذه الجلسة؟';

  @override
  String get deleteSessionMessage =>
      'سيؤدي هذا إلى حذف الجلسة وجميع العناصر الممسوحة ضوئياً بشكل دائم.';

  @override
  String get totalCost => 'إجمالي التكلفة';

  @override
  String get totalSales => 'إجمالي المبيعات';

  @override
  String get barcode => 'الباركود';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get quantity => 'الكمية';

  @override
  String get costPrice => 'سعر التكلفة';

  @override
  String get sellingPrice => 'سعر البيع';

  @override
  String get subtotalCost => 'إجمالي التكلفة الفرعية';

  @override
  String get subtotalSales => 'إجمالي المبيعات الفرعية';

  @override
  String get actions => 'الإجراءات';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get registerProduct => 'تسجيل المنتج';

  @override
  String get scannedBarcode => 'الباركود الممسوح';

  @override
  String get unknownBarcode =>
      'باركود غير معروف: @barcode. هل تريد تسجيل هذا المنتج؟';

  @override
  String get printReport => 'طباعة التقرير';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير Excel';

  @override
  String get exported => 'تم التصدير';

  @override
  String get pdfExported => 'تم تصدير ملف PDF بنجاح';

  @override
  String get excelExported => 'تم تصدير ملف Excel بنجاح';

  @override
  String get printSent => 'تم الإرسال إلى الطابعة';

  @override
  String get required => 'هذا الحقل مطلوب';

  @override
  String get invalidNumber => 'أدخل رقماً صحيحاً';

  @override
  String get productAdded => 'تمت إضافة المنتج إلى الجلسة';

  @override
  String get back => 'رجوع';

  @override
  String get menu => 'القائمة';

  @override
  String get themeMode => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get inventoryReport => 'تقرير المخزون';

  @override
  String get sessionReport => 'تقرير الجلسة';

  @override
  String get image => 'الصورة';

  @override
  String get batchNo => 'رقم التشغيلة';

  @override
  String get note => 'ملاحظة';

  @override
  String get expirationDate => 'تاريخ الصلاحية';

  @override
  String get color => 'اللون';

  @override
  String get customFields => 'حقول مخصصة';

  @override
  String get configureColumns => 'تكوين الأعمدة';

  @override
  String get configureColumnsHint =>
      'اختر الأعمدة التي تريد تتبعها لهذه الجلسة. الاسم والباركود إلزاميان.';

  @override
  String get maxColumnsReached => 'تم الوصول إلى الحد الأقصى وهو 10 أعمدة.';

  @override
  String get chooseImage => 'اختيار صورة';

  @override
  String get noImage => 'لا توجد صورة';

  @override
  String get saveImage => 'حفظ الصورة';

  @override
  String get otherField => 'أخرى';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get edit => 'تعديل';

  @override
  String get decrease => 'إنقاص';

  @override
  String get productUpdated => 'تم تحديث المنتج';

  @override
  String get deleteItemTitle => 'إزالة المنتج من الجلسة؟';

  @override
  String get deleteItemMessage =>
      'سيؤدي هذا إلى إزالة المنتج من الجلسة الحالية. يبقى المنتج مسجلاً.';
}
