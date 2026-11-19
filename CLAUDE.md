# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands are executed from the `property_valuer_pro` Flutter project directory:

```bash
# Dependencies & setup
flutter pub get

# Code analysis & linting
flutter analyze

# Run all unit and widget tests
flutter test --reporter=expanded

# Run a single test file
flutter test test/admin_auth_and_api_key_test.dart

# Run a single specific test by name
flutter test test/admin_auth_and_api_key_test.dart --plain-name "1. Correct password admin@valuer is accepted"

# Build APKs (locally or in CI)
flutter build apk --debug
flutter build apk --release
```

CI builds are automated via GitHub Actions in `.github/workflows/android-apk.yml`. It runs analysis, automated tests, and uploads `Property-Valuer-Pro-Release-APK` and `Property-Valuer-Pro-Test-APK` artifacts.

---

## Architecture & Code Structure

Property Valuer Pro is a Flutter Android application for chartered real estate valuers in Sri Lanka. It guides valuers through a structured 10-step appraisal pipeline, generates Microsoft Word (`.docx`) dossiers, performs on-device vector CAD sketching, and extracts deed/survey plan data via Google Gemini API.

```
lib/
├── app/
│   ├── app.dart              # MaterialApp entry, theme assignment, initialRoute
│   ├── routes.dart           # Route table (/step1../step10), areScreens3To10Frozen flag, FrozenStepScreen
│   └── theme.dart            # Material 3 tokens: Navy (#00173A), Teal (#159A91), Gold (#D4AF37)
├── core/
│   ├── constants/            # AppColors, AppConstants (workflow step names, quota limits)
│   ├── security/             # EncryptionService (Keystore/EncryptedSharedPreferences, defaultAdminPassword: "admin@valuer")
│   ├── services/
│   │   ├── ai_service.dart   # Gemini v1beta vision & multimodal OCR, model resolution, connectivity tests
│   │   ├── docx_service.dart # Raw OpenXML (.docx) ZIP packager; Executive Summary, Tables, Annexures
│   │   ├── ad_service.dart   # Meta Audience Network / AdMob simulation, impressions, interstitials
│   │   ├── entitlement_service.dart # Free vs. Paid license tier verification
│   │   ├── monthly_usage_service.dart # 10 free reports/month click tracker with date rollover
│   │   └── dossier_markdown_service.dart # Live Markdown case dossier generator synced across steps
│   ├── storage/
│   │   └── storage_service.dart # SharedPreferences & secure storage for profiles, drafts, active project
│   └── utilities/
│       └── memory_manager.dart # ImageCache bound clearer (optimizeMemory) and dimension constraints
├── features/                 # Feature-first modules with dedicated screens/
│   ├── dashboard/            # Screen 0: Project list, active draft resume, new valuation CTA
│   ├── profile/              # Screen 1: Valuer credentials, IVSL reg number, multi-profile drafts
│   ├── deed_extraction/      # Screen 2: Title deed 15-field OCR, camera/PDF ingest, tablet split-view
│   ├── plan_extraction/      # Screen 3: Survey plan OCR, multi-lot checkbox selection, boundary schedules
│   ├── inspection/           # Screen 4: Bank/branch, loan purpose, statutory compliance (NBRO, setbacks)
│   ├── location/             # Screen 5: GIS coords, road width/pavement, utilities, AI access polishing
│   ├── sketching/            # Screen 6: A3 Mini-CAD (CustomPainter, vector tools, bare land toggle)
│   ├── building_details/     # Screen 7: Structural specs (Roof/Walls/Floor), room steppers, 4 photo slots
│   ├── valuation/            # Screen 8: Land rate, GRC, depreciation, SAY, FSV, live calculation card
│   ├── report_generation/    # Screen 9 & 10: Final audit checklist, page budget, DOCX export & share
│   └── settings/             # AdminSettingsModal (password: admin@valuer, API key, model dropdown)
├── models/                   # Pure data models with toJson/fromJson for all workflow steps
└── widgets/                  # Reusable UI: ResponsiveWorkflowScaffold, LabeledTextField, SectionCard
```

---

## Key Domain Logic & Valuation Math

* **Sri Lankan Land Area Units:**
  * 1 Acre = 4 Roods = 160 Perches
  * 1 Rood = 40 Perches
  * 1 Perch = 272.25 sq.ft.
  * Extent calculation: `(acres * 160.0) + (roods * 40.0) + perches`
* **Valuation Formulas (`ValuationData`):**
  * `Land Value = Selected Perches * Adopted Rate/Perch`
  * `GRC = Total Floor Area (sq.ft) * Replacement Cost/sq.ft` (0 if bare land)
  * `Depreciation = GRC * (Depreciation % / 100)`
  * `Depreciated Building Value = GRC - Depreciation`
  * `Total Market Value = Land Value + Depreciated Building Value`
  * `SAY Value = Rounded to nearest 50,000 (if < 10M) or 100,000 (if >= 10M)`
  * `Forced Sale Value (FSV) = SAY Value * (FSV % / 100)` (Standard: 70% to 75%)

---

## AI & Admin Configuration Rules

* **Default Admin Password:** `admin@valuer` (configured in `EncryptionService.defaultAdminPassword`).
* **Active Gemini Models (`AiService.providerModelIds`):**
  * Default / Recommended: `gemini-1.5-flash` (`Gemini 1.5 Flash (Recommended)`)
  * Alternatives: `gemini-2.0-flash`, `gemini-1.5-pro`, `gemini-2.0-flash-lite`
  * Legacy identifiers (e.g., `3.1`, `3.5`, `3.8`) are automatically migrated to `gemini-1.5-flash`.
* **Admin Panel Integrity:** `AdminSettingsModal` is protected by administrator authentication. When making app improvements, do not alter admin panel authentication or API key configurations unless explicitly requested.

---

## Workflow Freeze State

* The workflow contains a development toggle in `lib/app/routes.dart`:
  * `AppRoutes.areScreens3To10Frozen` (boolean).
  * When `true`: Only Screen 0 (Dashboard), Screen 1 (Valuer Profile), and Screen 2 (Title Deed) are active. Screens 3 to 10 route to `FrozenStepScreen`, protecting completed early steps during focused testing.
  * When `false`: Full 10-screen end-to-end pipeline is unlocked.

---

## Memory Management Conventions (2GB-3GB RAM Devices)

* **Global Image Cache:** Budgeted at 30 MB (`PaintingBinding.instance.imageCache.maximumSizeBytes`) and 40 entries in `main.dart`.
* **Lifecycle Cleanup:** Every stateful screen managing controllers (`TextEditingController`, `TransformationController`) must implement `dispose()` and invoke `MemoryManager.optimizeMemory()`.
* **File Ingestion:** In `AiService`, document and photo files exceeding 12 MB are blocked to prevent heap surges during Base64 encoding.
* **Canvas Grid:** `_A3CadPainter` uses a 20px subgrid and 40px main grid wrapped in a `RepaintBoundary` with a 3px Euclidean distance point decimation filter to avoid excessive draw calls.
