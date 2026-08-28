# Agent Directives: Flutter Inventory Management System

You are an expert Flutter developer architecting a cross-platform (Windows, Linux, Android, iOS) inventory management application. Prioritize performance, clean architecture, and strict adherence to the defined tech stack.

## Tech Stack & Dependencies
*   **Framework:** Flutter (latest stable)
*   **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`).
*   **Local Database:** `sqflite` (mobile), `sqflite_common_ffi` (Windows/Linux).
*   **Localization:** `flutter_localizations`, `intl` (Must support `en` and `ar`).
*   **Export/Print:** `excel`, `pdf`, `printing`.
*   **Images:** `image_picker` (for mobile) / `file_selector` (for desktop), `path_provider` for local storage.

## Architecture Rules
1.  **Feature-Driven Directory Structure:** Organize by feature (`features/inventory`, `features/products`, `features/scanner`).
2.  **State Management:** Use Riverpod Notifiers to manage database state, scanner events, and dynamic column configurations. Do not use `setState` for core logic.
3.  **Database Access:** Isolate SQLite queries inside a Repository pattern layer. 

## Critical Implementation Details

### 1. Dynamic UI Rendering
*   The `Inventory_Sessions` table stores a `column_config` JSON string. 
*   When rendering the Data Table or the New Product Form, parse this JSON into a Dart model (`SessionConfig`).
*   Use conditional rendering (e.g., `if (sessionConfig.showColor) buildColorField()`) to dynamically build the UI. 

### 2. Image Handling
*   SQLite should not store BLOBs of images to maintain performance. 
*   Use `path_provider` to get the application documents directory. Copy the selected image file to this directory and save the relative/absolute file path as a string in the `image_path` column of the `Products` table.

### 3. USB Barcode Scanner Handling
*   Implement a `HardwareKeyboard` listener.
*   Capture keystrokes, buffer them, and trigger the DB search on the `Enter` key event. Focus nodes should not be required.

### 4. Localization (Arabic & English)
*   The UI must dynamically switch between LTR (English) and RTL (Arabic).
*   **PDF Generation:** The `pdf` package requires a custom TTF font (e.g., Noto Sans Arabic) to render Arabic text. You must load this font from assets during PDF generation to prevent text corruption.

### 5. Data Export Layout
*   Excel and PDF files must only generate columns defined as `true` in the session's `column_config` JSON.
*   Row 1 must be: Total Cost: [Value] | Total Sales: [Value]
*   Table headers begin on Row 3.