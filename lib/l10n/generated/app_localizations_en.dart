// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inventory System';

  @override
  String get homeTitle => 'Inventory Sessions';

  @override
  String get newSession => 'New Session';

  @override
  String get sessionName => 'Session name';

  @override
  String get create => 'Create';

  @override
  String get createSession => 'Create Session';

  @override
  String get continueScanning =>
      'Please scan a barcode to begin, or register a new product.';

  @override
  String get sessionCreated => 'Session created';

  @override
  String get noSessions => 'No sessions yet. Create your first one.';

  @override
  String get searchSessions => 'Search sessions';

  @override
  String get noResults => 'No matching sessions';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSessionTitle => 'Delete this session?';

  @override
  String get deleteSessionMessage =>
      'This will permanently delete the session and all scanned items.';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get barcode => 'Barcode';

  @override
  String get productName => 'Product Name';

  @override
  String get companyName => 'Company Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get subtotalCost => 'Subtotal Cost';

  @override
  String get subtotalSales => 'Subtotal Sales';

  @override
  String get actions => 'Actions';

  @override
  String get newProduct => 'New Product';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get registerProduct => 'Register Product';

  @override
  String get scannedBarcode => 'Scanned barcode';

  @override
  String get unknownBarcode =>
      'Unknown barcode: @barcode. Register this product?';

  @override
  String get printReport => 'Print Report';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get exported => 'Exported';

  @override
  String get pdfExported => 'PDF exported successfully';

  @override
  String get excelExported => 'Excel exported successfully';

  @override
  String get printSent => 'Sent to printer';

  @override
  String get required => 'This field is required';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get productAdded => 'Product added to session';

  @override
  String get back => 'Back';

  @override
  String get menu => 'Menu';

  @override
  String get themeMode => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get inventoryReport => 'Inventory Report';

  @override
  String get sessionReport => 'Session Report';

  @override
  String get image => 'Image';

  @override
  String get batchNo => 'Batch No';

  @override
  String get note => 'Note';

  @override
  String get expirationDate => 'Expiration Date';

  @override
  String get color => 'Color';

  @override
  String get customFields => 'Custom Fields';

  @override
  String get configureColumns => 'Configure Columns';

  @override
  String get configureColumnsHint =>
      'Choose which columns to track for this session. Name and Barcode are required.';

  @override
  String get maxColumnsReached => 'Maximum of 10 columns reached.';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get noImage => 'No image';

  @override
  String get saveImage => 'Save image';

  @override
  String get otherField => 'Other';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get edit => 'Edit';

  @override
  String get decrease => 'Decrease';

  @override
  String get productUpdated => 'Product updated';

  @override
  String get deleteItemTitle => 'Remove product from session?';

  @override
  String get deleteItemMessage =>
      'This removes the product from the current session. The product stays registered.';
}
