# Property Valuer Pro (Android)

Native Android (Kotlin + Jetpack Compose) application for Chartered Property Valuers in Sri Lanka. Guides practitioners through a structured 10-step valuation workflow and compiles editable Microsoft Word (`.docx`) appraisal dossiers.

## Features

- **10-Step Valuation Workflow**:
  1. **Dashboard**: Project initialization, active/completed valuation dossiers, banking client overview, and monthly free quota status (10 reports/month with automatic `YYYY-MM` rollover).
  2. **Valuer Profile & AI Style Learning**: Multi-draft chartered valuer chambers credentials, template upload (up to 3 templates on Free tier), AI convention analysis, workflow guide, and Markdown dossier preview.
  3. **Title Deed Extraction**: Document attachment via Android Photo Picker, Document Picker, or Camera capture, plus Gemini AI OCR extraction and manual verification with uncertain-field highlighting.
  4. **Survey Plan & Lots**: Cadastral survey plan extraction and Acres–Roods–Perches lot extent calculation (`totalPerches = acres*160 + roods*40 + perches`).
  5. **Inspection & Statutory Compliance**: Bank/institution selection, valuation purpose, administrative divisions, and statutory status tracking (Street Lines, Building Limits, NBRO Clearance).
  6. **Location & GIS Accessibility**: GPS coordinate detection (`LocationManager`), manual WGS-84 pin entry, roadway & utility checklists, and AI formal valuation phrasing polish.
  7. **A3 Mini-CAD Sketching**: Bare Land bypass mode or interactive A3-aspect-ratio drafting canvas with grid, Line/Rectangle/Circle/Freehand/Dimension/Text tools, orientation toggle, and Undo/Redo.
  8. **Building Details & Photo Register**: Construction specifications, accommodation room steppers, land characteristics, and a 4-slot property photograph register.
  9. **Valuation Engine & SWOC**: Real-time calculation of Land Value, Gross Replacement Cost (GRC), Depreciation, Depreciated Building Value, Total Market Value, SAY Value rounding, and Forced Sale Value (FSV), alongside comparable sales and SWOC analysis.
  10. **Final Review & Editable DOCX Export**: Mandatory 3/4/5-page budget selector, 8-step pre-generation checklist, native OpenXML `.docx` report generation, and `FileProvider` Word open/share actions.

- **Admin Settings** (password-gated, default `admin@valuer`):
  - Android Keystore (AES-256-GCM) encrypted storage for user-provided Gemini API key, dynamic Gemini model discovery, live connection test, monthly quota management, commercial license toggle, ad banner/interstitial controls, and workflow freeze toggle.

- **Adaptive Layouts**:
  - Compact phone workflow header with progress bar and bottom navigation, plus wide-screen/tablet `NavigationRail` sidebar (`>= 720dp`).

## Architecture

- **Language & UI**: Kotlin, Jetpack Compose, Material 3, Manrope & JetBrains Mono bundled fonts
- **Navigation**: Type-safe Jetpack Navigation Compose (`@Serializable` routes)
- **State**: `AndroidViewModel` + `StateFlow` (`collectAsStateWithLifecycle`)
- **Security & Storage**: Android Keystore AES-256-GCM (`SecureStorage`), `SharedPreferences` + `kotlinx.serialization` (`ValuationRepository`), `FileProvider` for `.docx` & camera sharing
- **Report Compilation**: Native OpenXML `.docx` generator (`ZipOutputStream`) in `DocxService`
