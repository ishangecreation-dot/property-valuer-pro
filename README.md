# Property Valuer Pro – Flutter Android Application

[![Build Android APK](https://github.com/ishangecreation-dot/property-valuer-pro/actions/workflows/android-apk.yml/badge.svg)](https://github.com/ishangecreation-dot/property-valuer-pro/actions/workflows/android-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.29-blue.svg)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-6.0%2B%20%28API%2023%29-green.svg)](https://developer.android.com)
[![Stitch UI/UX](https://img.shields.io/badge/Google%20Stitch-10%20Screens-teal.svg)](https://stitch.googleapis.com)

**Property Valuer Pro** is a high-performance, memory-optimized Flutter Android application designed for chartered valuers, bank panel valuers, and real estate assessment professionals across Sri Lanka. It combines structured field survey capture, AI-assisted document extraction, vector A3 building sketching, real-time valuation mathematics, and automated Microsoft Word (.docx) report dossier generation.

---

## 1. Connected 10-Screen Workflow

The application guides the valuer through exactly 10 connected screens:

1. **Dashboard & Admin Settings:** Project management, active valuation resumption, encrypted AI API key configuration, and non-intrusive ad placeholders.
2. **Professional Valuer Profile:** User-managed chartered credentials, registration number, practice address, and DOCX template management (up to 3 in the free version).
3. **Title Deed Details & AI Extraction:** Multi-page PDF/image upload and back-camera capture; AI extraction of 15 legal deed fields with certainty indicators; tablet split-view.
4. **Survey Plan & Lot Selection:** AI extraction of plan number, date, surveyor, and multi-lot checkbox selection with boundary schedules and automatic perch aggregation.
5. **Purpose, Inspection & Statutory Details:** Selectable financial institutions, loan purpose chips, administrative divisions, and statutory compliance matrix (Street Lines, Building Limits, NBRO).
6. **Location, Access & Google Maps:** GIS coordinate pinning, step-by-step driving directions, road width/pavement chips, available utilities, and AI phrasing assistant.
7. **A3 Building Sketching Mini-CAD:** Bare land skip option, A3 grid canvas (1"x1" with 100 subgrids), scale selection (1"=20'), vector tools (Line, Rect, Circle, Freehand, Dimensions), and S-Pen / stylus pressure support.
8. **Building Details & Property Photographs:** Multi-building structural specs (Roof, Walls, Floor, Bath), +/- room counters, age, condition, and 4 required photographic register slots.
9. **Valuation Calculations & Market Evidence:** Real-time computation of Land Value, GRC, Depreciation, Depreciated Building Value, Total Market Value, SAY Value, and FSV (75%); SWOC analysis and collateral risk rating.
10. **Final Review & Generate DOCX Report:** 8-step review checklist with edit shortcuts, mandatory page budget selection (3, 4, or 5 pages), and 1-click DOCX generation.
    - **Post-Generation Screen:** Open in Word, Share via Email/Messaging, Save & Archive, and secondary ad banner.

---

## 2. Advanced Memory Management & Low-RAM Optimization

Tailored for budget Android smartphones and tablets (Android 6.0+ / 2GB-3GB RAM):
- **Adaptive Screen Lifecycle:** Controllers, image providers, and camera sessions are disposed immediately upon leaving screens.
- **Incremental Image Processing:** Thumbnails (300-600px) and previews (800-1280px) are downsampled; originals are kept on disk, not in heap RAM.
- **Vector A3 Mini-CAD:** Lightweight CustomPainter with viewport culling draws only visible grid lines, avoiding heavy raster bitmap allocations.
- **Decoupled Binary Storage:** Metadata and valuation parameters reside in lightweight local SQLite/SharedPreferences; large PDFs and images are stored as file references.

---

## 3. Automated GitHub Actions APK Build

The repository includes `.github/workflows/android-apk.yml` configured to automatically:
1. Install Java 17 and Flutter stable.
2. Run code analysis (`flutter analyze`) and unit tests (`flutter test`).
3. Compile the release APK (`flutter build apk --release`).
4. Build ABI-split APKs for ARM64, ARM32, and x86_64.
5. Upload installable APKs as downloadable workflow artifacts.

### Manual Trigger:
Navigate to the **Actions** tab in GitHub and click **Run workflow** on `Build Android APK`.
