# Product Requirements Document (PRD)
**Project Name:** Multi-Platform Inventory Management System
**Primary Platforms:** Windows, Linux, Android, iOS
**Tech Stack:** Flutter, SQLite, Riverpod

## 1. Overview
A cross-platform inventory management application designed to handle barcode scanning, product registration, and inventory counting. The system requires full bilingual support (English and Arabic), a blue-based light/dark theme, and dynamic column configuration per inventory session.

## 2. Core Features & Workflows

### 2.1. Home Page (Inventory Session Creation)
*   **Action:** User creates a new inventory stock session by entering a session name.
*   **Dynamic Column Configuration:** Before finalizing creation, a configuration menu prompts the user to select which columns to display and track for this specific session. 
*   **Available Columns (Max 10 active at a time for UI performance):**
    0.  Product ID (Always tracked in DB, never displayed on UI by default)
    1.  Product Name / اسم الدواء (Required)
    2.  Image / صورة
    3.  Barcode / الباركود (Required)
    4.  Sales Price / سعر البيع
    5.  Cost Price / سعر التكلفة
    6.  Batch No / رقم التشغيلة
    7.  Note / ملاحظة
    8.  Expiration Date / تاريخ الصلاحية
    9.  Color / اللون
    10. Custom Fields (Up to 5 dynamic fields: Other 1, Other 2, etc. User can rename these per session).
*   **Data Stored:** Session Name, Creation Timestamp, JSON map of selected columns and custom field labels.

### 2.2. Barcode Scanning System
*   **Hardware Interface:** USB Barcode Scanner (functions as a hardware keyboard input).
*   **Logic Flow:**
    *   Listen for keyboard events globally or on the active screen.
    *   Buffer rapid keystrokes ending with an `Enter` keystroke to capture the barcode.
    *   Query SQLite database for the scanned barcode.
    *   **Condition A (Barcode Exists):** Increment quantity in the active session.
    *   **Condition B (Barcode Does Not Exist):** Trigger "New Product" modal.

### 2.3. Dynamic New Product Registration (Modal/Popup)
*   Triggered automatically when an unknown barcode is scanned.
*   **Dynamic Form:** The input fields rendered in this modal are strictly determined by the columns selected during the session creation (Step 2.1). 
*   **Action:** Save to SQLite `Products` table, capturing all active fields, then automatically add 1 unit to the active inventory session. Images should be saved locally, storing the file path in the database.

### 2.4. Main Inventory Page (Active Session)
*   **Top Bar Displays (Pinned):** 
    *   Total Cost (Sum of Cost Price * Quantity for all items in session)
    *   Total Sales (Sum of Selling Price * Quantity for all items in session)
*   **Dynamic Data Table:** Columns are generated based on the session's configuration.
*   **Actions:** 
    *   Print Report button.
    *   Export to PDF.
    *   Export to Excel.

## 3. Localization & Theming
*   **Languages:** English (LTR) and Arabic (RTL). App must support dynamic locale switching.
*   **Theme:** Primary Color: Blue. Modes: Dark Mode and Light Mode with a global toggle.

## 4. Export & Reporting Requirements
*   **Exports:** Both Excel (.xlsx) and PDF exports must respect the dynamic column configuration. Only the selected columns for that session should be exported.
*   **Header:** The top rows must prominently display "Total Cost" and "Total Sales".
*   **PDF Compatibility:** Must support Arabic font rendering.

## 5. Database Schema (SQLite)

**Table: `Inventory_Sessions`**
*   `id` (INTEGER, Primary Key, Auto-increment)
*   `name` (TEXT, Not Null)
*   `created_at` (DATETIME, Default Current Timestamp)
*   `column_config` (TEXT) -> Stores a JSON representation of active columns and custom field labels (e.g., `{"show_image": true, "show_batch": false, "custom_1": "Supplier"}`).

**Table: `Products`**
*   `id` (INTEGER, Primary Key, Auto-increment)
*   `barcode` (TEXT, Unique, Not Null)
*   `name` (TEXT, Not Null)
*   `image_path` (TEXT, Nullable)
*   `cost_price` (REAL, Nullable)
*   `selling_price` (REAL, Nullable)
*   `batch_no` (TEXT, Nullable)
*   `note` (TEXT, Nullable)
*   `expiration_date` (TEXT, Nullable)
*   `color` (TEXT, Nullable)
*   `other_1` (TEXT, Nullable)
*   `other_2` (TEXT, Nullable)
*   `other_3` (TEXT, Nullable)
*   `other_4` (TEXT, Nullable)
*   `other_5` (TEXT, Nullable)

**Table: `Inventory_Items`**
*   `id` (INTEGER, Primary Key, Auto-increment)
*   `session_id` (INTEGER, Foreign Key -> Inventory_Sessions.id)
*   `product_id` (INTEGER, Foreign Key -> Products.id)
*   `quantity` (INTEGER, Default 1)